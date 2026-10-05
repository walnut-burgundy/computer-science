"""Small, dependency-free models of GPU renderer contracts.

These are not a renderer.  They make host/GPU boundary assumptions explicit enough
to test without requiring a graphics device.  The same invariants can then be used
as fixtures for an Idriç shader backend and its runtime.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Sequence


@dataclass(frozen=True)
class UploadState:
    """Everything that can make cached record bytes stale.

    ``version`` describes the source payload.  The other fields describe how those
    bytes are interpreted or where derived bytes are placed in a shared GPU buffer.
    """

    version: int
    offset: int
    records: int
    repeats: int
    layout: str


def needs_upload(previous: UploadState | None, current: UploadState) -> bool:
    """True when reusing the previous GPU bytes would be unsound."""

    return previous != current


def align_up(nbytes: int, alignment: int) -> int:
    if nbytes < 0:
        raise ValueError("nbytes must be non-negative")
    if alignment <= 0:
        raise ValueError("alignment must be positive")
    return nbytes + (-nbytes % alignment)


def aligned_claims(sizes: Iterable[int], alignment: int) -> list[tuple[int, int]]:
    """Return ``(offset, padded_size)`` claims for one frame's shared buffer."""

    used = 0
    claims = []
    for size in sizes:
        padded = align_up(size, alignment)
        claims.append((used, padded))
        used += padded
    return claims


def validate_resource_bindings(
    declared: Sequence[str],
    bound: Sequence[str],
) -> None:
    """Require the host resource table to match the shader interface exactly."""

    declared_set = set(declared)
    bound_set = set(bound)
    missing = declared_set - bound_set
    extra = bound_set - declared_set
    if missing or extra:
        pieces = []
        if missing:
            pieces.append("missing: " + ", ".join(sorted(missing)))
        if extra:
            pieces.append("extra: " + ", ".join(sorted(extra)))
        raise ValueError("; ".join(pieces))


@dataclass(frozen=True)
class PipelineKey:
    """Facts baked into a pipeline rather than changed around a draw."""

    module: str
    layout: str
    depth_test: bool
    blend: str
    stencil: str
    samples: int


@dataclass(frozen=True)
class RasterDiff:
    """Pixel differences partitioned into edge and interior regions."""

    edge_pixels: int
    interior_pixels: int
    max_channel_error: int

    @property
    def cross_api_equivalent(self) -> bool:
        """A conservative cross-rasterizer oracle.

        Edge pixels may differ because rasterization/sample rules differ.  Interior
        pixels may not.  This is intentionally stricter than a visual similarity
        score and weaker than byte equality.
        """

        return self.interior_pixels == 0


def compare_rgb(
    reference: Sequence[tuple[int, int, int]],
    candidate: Sequence[tuple[int, int, int]],
    edge_mask: Sequence[bool],
    tolerance: int = 0,
) -> RasterDiff:
    if not (len(reference) == len(candidate) == len(edge_mask)):
        raise ValueError("reference, candidate, and edge_mask must have equal length")
    if tolerance < 0:
        raise ValueError("tolerance must be non-negative")

    edge_pixels = 0
    interior_pixels = 0
    max_error = 0
    for a, b, edge in zip(reference, candidate, edge_mask):
        error = max(abs(x - y) for x, y in zip(a, b))
        max_error = max(max_error, error)
        if error <= tolerance:
            continue
        if edge:
            edge_pixels += 1
        else:
            interior_pixels += 1
    return RasterDiff(edge_pixels, interior_pixels, max_error)


def one_frame_late_readback(
    frames: Iterable[bytes],
    *,
    drain: bool,
) -> list[bytes]:
    """Model an asynchronous readback which is consumed one frame later."""

    pending = None
    out: list[bytes] = []
    for frame in frames:
        if pending is not None:
            out.append(pending)
        pending = frame
    if drain and pending is not None:
        out.append(pending)
    return out


@dataclass(frozen=True)
class PathCost:
    """End-to-end cost components for deciding whether a GPU path is actually faster."""

    upload: float
    launch_and_bind: float
    compute: float
    synchronization: float
    readback: float

    @property
    def total(self) -> float:
        return (
            self.upload
            + self.launch_and_bind
            + self.compute
            + self.synchronization
            + self.readback
        )


def choose_faster(cpu: PathCost, gpu: PathCost) -> str:
    """Choose using end-to-end cost, not arithmetic throughput alone."""

    return "gpu" if gpu.total < cpu.total else "cpu"

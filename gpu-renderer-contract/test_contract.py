from __future__ import annotations

import unittest

from contract import (
    PathCost,
    PipelineKey,
    UploadState,
    aligned_claims,
    choose_faster,
    compare_rgb,
    needs_upload,
    one_frame_late_readback,
    validate_resource_bindings,
)


class UploadInvalidationTests(unittest.TestCase):
    def test_unchanged_payload_still_reuploads_when_derived_separator_role_changes(self):
        # Mirrors the ManimGL 9d57bcf failure: a run member can keep the same
        # source bytes and offset while changing from "last" to "not last".
        before = UploadState(version=7, offset=256, records=5, repeats=0, layout="curve-v1")
        after = UploadState(version=7, offset=256, records=5, repeats=1, layout="curve-v1")
        self.assertTrue(needs_upload(before, after))

    def test_offset_record_count_and_layout_are_cache_inputs(self):
        base = UploadState(version=7, offset=256, records=5, repeats=0, layout="curve-v1")
        variants = [
            UploadState(version=7, offset=512, records=5, repeats=0, layout="curve-v1"),
            UploadState(version=7, offset=256, records=6, repeats=0, layout="curve-v1"),
            UploadState(version=7, offset=256, records=5, repeats=0, layout="curve-v2"),
        ]
        self.assertTrue(all(needs_upload(base, variant) for variant in variants))

    def test_identical_state_can_reuse_gpu_bytes(self):
        state = UploadState(version=7, offset=256, records=5, repeats=1, layout="curve-v1")
        self.assertFalse(needs_upload(state, state))


class BufferLayoutTests(unittest.TestCase):
    def test_shared_buffer_claims_respect_dynamic_offset_alignment(self):
        claims = aligned_claims([12, 257, 1], alignment=256)
        self.assertEqual(claims, [(0, 256), (256, 512), (768, 256)])
        self.assertTrue(all(offset % 256 == 0 for offset, _ in claims))

    def test_zero_length_claim_does_not_break_following_alignment(self):
        claims = aligned_claims([0, 8], alignment=256)
        self.assertEqual(claims, [(0, 0), (0, 256)])


class ShaderInterfaceTests(unittest.TestCase):
    def test_every_declared_resource_must_be_bound(self):
        with self.assertRaisesRegex(ValueError, "missing: dark_texture"):
            validate_resource_bindings(
                ["data", "sampler", "light_texture", "dark_texture"],
                ["data", "sampler", "light_texture"],
            )

    def test_host_and_shader_tables_must_not_silently_drift(self):
        with self.assertRaisesRegex(ValueError, "extra: stale_texture"):
            validate_resource_bindings(
                ["data", "sampler"],
                ["data", "sampler", "stale_texture"],
            )

    def test_matching_tables_are_valid(self):
        validate_resource_bindings(["data", "sampler"], ["sampler", "data"])


class PipelineKeyTests(unittest.TestCase):
    def test_baked_render_state_is_part_of_cache_identity(self):
        base = PipelineKey("stroke", "layout-v1", True, "alpha", "keep", 1)
        changed = [
            PipelineKey("stroke", "layout-v1", False, "alpha", "keep", 1),
            PipelineKey("stroke", "layout-v1", True, "opaque", "keep", 1),
            PipelineKey("stroke", "layout-v1", True, "alpha", "increment", 1),
            PipelineKey("stroke", "layout-v1", True, "alpha", "keep", 4),
            PipelineKey("stroke", "layout-v2", True, "alpha", "keep", 1),
        ]
        self.assertEqual(len({base, *changed}), 1 + len(changed))


class CrossApiOracleTests(unittest.TestCase):
    def test_cross_api_comparison_can_tolerate_edge_only_rasterization_changes(self):
        ref = [(0, 0, 0), (20, 20, 20), (255, 255, 255)]
        new = [(0, 0, 0), (23, 20, 20), (255, 255, 255)]
        report = compare_rgb(ref, new, [False, True, False])
        self.assertTrue(report.cross_api_equivalent)
        self.assertEqual(report.edge_pixels, 1)
        self.assertEqual(report.interior_pixels, 0)

    def test_interior_change_is_not_excused_as_a_rasterizer_difference(self):
        ref = [(0, 0, 0), (20, 20, 20), (255, 255, 255)]
        new = [(0, 0, 0), (20, 20, 20), (250, 255, 255)]
        report = compare_rgb(ref, new, [False, True, False])
        self.assertFalse(report.cross_api_equivalent)
        self.assertEqual(report.interior_pixels, 1)


class AsyncReadbackTests(unittest.TestCase):
    def test_one_frame_late_readback_preserves_every_frame_when_drained(self):
        frames = [b"0", b"1", b"2", b"3"]
        self.assertEqual(one_frame_late_readback(frames, drain=True), frames)

    def test_failure_to_drain_loses_only_the_final_frame_and_is_detectable(self):
        frames = [b"0", b"1", b"2", b"3"]
        self.assertEqual(one_frame_late_readback(frames, drain=False), frames[:-1])


class EndToEndCostTests(unittest.TestCase):
    def test_gpu_is_not_selected_from_kernel_time_alone(self):
        # The GPU arithmetic is faster, but transfer + launch + synchronization
        # makes this tiny one-shot job slower end-to-end.
        cpu = PathCost(0, 0, 8, 0, 0)
        gpu = PathCost(3, 2, 1, 2, 3)
        self.assertEqual(choose_faster(cpu, gpu), "cpu")

    def test_resident_batched_vector_work_can_flip_the_decision(self):
        cpu = PathCost(0, 0, 80, 0, 0)
        gpu = PathCost(0, 2, 8, 1, 0)
        self.assertEqual(choose_faster(cpu, gpu), "gpu")


if __name__ == "__main__":
    unittest.main()

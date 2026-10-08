module Model

import Data.List
import Data.Maybe
import System

%default covering

record Dyad where
  constructor D
  numerator : Integer
  exponent : Nat

powerTwo : Nat -> Integer
powerTwo Z = 1
powerTwo (S n) = 2 * powerTwo n

integer : Integer -> Dyad
integer n = D n 0

plus : Dyad -> Dyad -> Dyad
plus (D a p) (D b q) = D (a * powerTwo q + b * powerTwo p) (p + q)

neg : Dyad -> Dyad
neg (D a p) = D (-a) p

minus : Dyad -> Dyad -> Dyad
minus a b = plus a (neg b)

times : Dyad -> Dyad -> Dyad
times (D a p) (D b q) = D (a*b) (p+q)

half : Dyad -> Dyad
half (D a p) = D a (S p)

same : Dyad -> Dyad -> Bool
same (D a p) (D b q) = a * powerTwo q == b * powerTwo p

sumD : List Dyad -> Dyad
sumD = foldl plus (integer 0)

sameList : List Dyad -> List Dyad -> Bool
sameList [] [] = True
sameList (a::as) (b::bs) = same a b && sameList as bs
sameList _ _ = False

triples : List (List Nat)
triples = [[a,b,c] | a <- [0..5], b <- [0..5], c <- [0..5], a < b, b < c]

overlap : List Nat -> List Nat -> Nat
overlap s t = length (filter (\i => elem i t) s)

neighbor : List Nat -> List Nat -> Bool
neighbor s t = s /= t && (overlap s t == 0 || overlap s t == 2)

sample : Integer -> Integer -> Dyad
sample seed position = D (mod (seed*19 + position*7) 23 - 11) 2

-- Independent incidence-map formula for scatter and side injection.
scatter : List Dyad -> Dyad -> List Dyad
scatter central star = map (\s => half (minus
  (sumD (map snd (filter (\entry => elem (fst entry) s) (zip [0..5] central)))) star)) triples

sideInject : List Dyad -> List Dyad
sideInject side = map (\s => sumD (map (\entry =>
  let ((target, source), value) = entry in
  times (D (1 - cast (overlap target source)) 1) value)
  (filter (\entry => fst (fst entry) == s) (zip pairs side)))) triples
  where
  pairs : List (List Nat, List Nat)
  pairs = [(s,t) | s <- triples, t <- triples, neighbor s t]

network : String -> List Dyad -> List Dyad -> List Dyad -> List Dyad -> Dyad ->
          (List Dyad, List Dyad, List Dyad, Dyad)
network mode source target side central star =
  let pairs = [(s,t) | s <- triples, t <- triples, neighbor s t]
      copied = map (\entry => sumD (map snd (filter (\x => fst x == snd entry)
                    (zip triples source)))) pairs
      gathered = map (\i => sumD (map snd (filter (\entry => elem i (fst entry))
                    (zip triples source)))) [0..5]
      y0 = zipWith minus target (sideInject side)
      y1 = zipWith minus y0 (scatter central star)
      a2 = zipWith plus side copied
      c3 = zipWith plus central gathered
      star3 = plus star (sumD source)
      y4 = zipWith plus y1 (scatter c3 star3)
      y5 = zipWith (if mode == "wrong-side" then minus else plus) y4 (sideInject a2)
      c6 = zipWith minus c3 gathered
      a7 = if mode == "no-restore" then a2 else zipWith minus a2 copied
      star6 = minus star3 (sumD source)
  in (y5, a7, c6, star6)

networkCase : String -> Integer -> List Dyad -> Bool
networkCase mode seed source =
  let target = map (sample seed) [0..19]
      pairs = [(s,t) | s <- triples, t <- triples, neighbor s t]
      side = map (sample (seed+3)) (map cast [1..length pairs])
      central = map (sample (seed+5)) [0..5]
      star = D (seed+7) 1
      (result, restoredSide, restoredCentral, restoredStar) = network mode source target side central star
  in sameList result (zipWith plus target source) && sameList side restoredSide &&
     sameList central restoredCentral && same star restoredStar

complexPlus : (Dyad,Dyad) -> (Dyad,Dyad) -> (Dyad,Dyad)
complexPlus (a,b) (c,d) = (plus a c, plus b d)

complexTimes : (Dyad,Dyad) -> (Dyad,Dyad) -> (Dyad,Dyad)
complexTimes (a,b) (c,d) = (minus (times a c) (times b d), plus (times a d) (times b c))

iTimes : (Dyad,Dyad) -> (Dyad,Dyad)
iTimes (a,b) = (neg b,a)

complexSame : (Dyad,Dyad) -> (Dyad,Dyad) -> Bool
complexSame (a,b) (c,d) = same a c && same b d

complexHalf : (Dyad,Dyad) -> (Dyad,Dyad)
complexHalf (a,b) = (half a,half b)

complexMinus : (Dyad,Dyad) -> (Dyad,Dyad) -> (Dyad,Dyad)
complexMinus (a,b) (c,d) = (minus a c,minus b d)

phase : (Dyad,Dyad) -> (Dyad,Dyad) -> ((Dyad,Dyad),(Dyad,Dyad))
phase u v = (complexHalf (complexPlus (complexPlus u v) (iTimes (complexMinus u v))),
             complexHalf (complexMinus (complexPlus u v) (iTimes (complexMinus u v))))

truncateZero : Dyad -> Dyad
truncateZero (D a p) = integer (if a < 0 then -(div (-a) (powerTwo p)) else div a (powerTwo p))

phaseCase : String -> Integer -> Integer -> Bool
phaseCase mode a b =
  let u = (D a 2, D (a-1) 2)
      v = (D b 2, D (b+1) 2)
      (first,second) = phase u (iTimes v)
      factor = (D 1 1,D (-1) 1)
      secondS = if mode == "wrong-phase" then second else iTimes second
      actual = (complexTimes factor first, complexTimes factor secondS)
      expected = (complexHalf (complexPlus u v), complexHalf (complexMinus u v))
  in complexSame (fst actual) (fst expected) && complexSame (snd actual) (snd expected)

evenValue : Integer -> Bool
evenValue n = mod n 2 == 0

parityShift : Bool -> Integer -> Integer
parityShift condition control = if condition then control else 0

addressNetwork : Integer -> Integer -> Integer -> (Integer,Integer)
addressNetwork c u w =
  let u1 = u - parityShift (evenValue w) c
      w2 = w - parityShift (evenValue u1) c
      u3 = u1 + parityShift (evenValue w2) c
      w4 = w2 + parityShift (evenValue u3) c
      w5 = w4 + parityShift (not (evenValue u3)) c
      u6 = u3 + parityShift (not (evenValue w5)) c
      w7 = w5 - parityShift (not (evenValue u6)) c
      u8 = u6 - parityShift (not (evenValue w7)) c
  in (u8,w7)

addressCase : Integer -> Integer -> Integer -> Bool
addressCase c u w = addressNetwork c u w ==
  (if c == 0 then u else if evenValue u then u+1 else u-1, w)

pack : Integer -> List Integer -> Integer
pack base = foldr (\coefficient, rest => coefficient + base*rest) 0

decode : Nat -> Integer -> Integer -> List Integer
decode Z base value = []
decode (S n) base value =
  let raw = mod value base
      residue = if raw < 0 then raw+base else raw
      digit = if 2*residue >= base then residue-base else residue
  in digit :: decode n base (div (value-digit) base)

at : Nat -> List Integer -> Integer
at Z (a::as) = a
at (S n) (a::as) = at n as
at _ [] = 0

ringCase : String -> Integer -> Integer -> Bool
ringCase mode seed other =
  let left = map (\j => mod (seed*3+j*5) 13-6) [0..3]
      right = map (\j => mod (other*7+j*3) 13-6) [0..3]
      expanded = decode 7 4096 (pack 4096 left * pack 4096 right)
      candidate = map (\j => if mode == "zero" then 0 else if mode == "wrong-wrap" then at j expanded + at (j+4) expanded
                              else at j expanded - at (j+4) expanded) [0..3]
      direct = map (\k => sum [ (if i+j >= 4 then -1 else 1) * at i left * at j right
                             | i <- [0..3], j <- [0..3], i+j == k || i+j == k+4]) [0..3]
  in candidate == direct

report : String -> List Bool -> IO Bool
report label results = do
  let passed = length (filter id results)
  putStrLn (label ++ " " ++ show passed ++ "/" ++ show (length results))
  pure (all id results)

main : IO ()
main = do
  args <- getArgs
  let mode = fromMaybe "correct" (head' (drop 1 args))
  n <- report "Gaussian scalar invocation h=6, nonzero scratch" $
    [networkCase mode seed (map (sample seed) [0..19]) | seed <- [0..11]] ++
    [networkCase mode 17 (map (\j => integer (if i==j then 1 else 0)) [0..19]) | i <- [0..19]]
  a <- report "eight address shifts, signed addresses" [addressCase c u w | c <- [0..1], u <- [-8..8], w <- [-8..8]]
  p <- report "exact H0=b S C S" [phaseCase mode u v | u <- [-4..4], v <- [-4..4]]
  r <- report "signed packing and negacyclic recovery" [ringCase mode u v | u <- [0..12], v <- [0..12]]
  let late = half (plus (D 3 1) (D 1 1))
  let early = half (plus (truncateZero (D 3 1)) (truncateZero (D 1 1)))
  t <- report "early truncation changes completed layer" [not (same late early), same late (integer 1)]
  if n && a && p && r && t then pure () else exitFailure

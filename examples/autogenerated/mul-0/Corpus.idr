module Corpus

import Data.List

%default covering

-- Independent corpus generator: the existing Integer runtime supplies products.
-- It imports none of the candidate network, limb, layout or convolution modules.
powerTwo : Nat -> Integer
powerTwo Z = 1
powerTwo (S n) = 2 * powerTwo n

row : String -> Nat -> Nat -> Integer -> Integer -> String
row name leftWidth rightWidth left right =
  "mul\t" ++ name ++ "\t" ++ show leftWidth ++ "\t" ++ show rightWidth ++ "\t" ++
  show left ++ "\t" ++ show right ++ "\t" ++ show (left*right)

widths : List Nat
widths = [0,1,7,8,15,16,31,32,33,63,64,65,127,128,129,255,256,257,1023,1024,1025]

boundary : Nat -> List String
boundary width =
  let limit = powerTwo width
      high = if width == 0 then 0 else div limit 2
      one = if width == 0 then 0 else 1
      alternating = div (limit-1) 3
      deterministic = mod (123456789 * limit + 9876543210123456789) limit
  in [row ("zero-" ++ show width) width width 0 (limit-1),
      row ("one-" ++ show width) width width one (limit-1),
      row ("power-" ++ show width) width width high high,
      row ("carry-" ++ show width) width width (limit-1) (limit-1),
      row ("alternating-" ++ show width) width width alternating (limit-1-alternating),
      row ("deterministic-" ++ show width) width width deterministic (limit-1-deterministic),
      row ("leading-zero-" ++ show width) (width+33) (width+65) (limit-1) high,
      row ("unequal-" ++ show width) width 1 (limit-1) 1]

main : IO ()
main = do
  putStrLn "# mul-corpus-v1\top\tid\tleft_bits\tright_bits\tleft_decimal\tright_decimal\tproduct_decimal"
  traverse_ putStrLn [row (show a ++ "x" ++ show b) 8 8 a b | a <- [0..255], b <- [0..255]]
  traverse_ putStrLn (concatMap boundary widths)

# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  # Standard library
  unittest, times, random,
  # Internals
  ../constantine/tower_field_extensions/[abelian_groups, fp6_1_plus_i],
  ../constantine/config/[common, curves],
  ../constantine/arithmetic,
  # Test utilities
  ../helpers/prng

const Iters = 128

var rng: RngState
let seed = uint32(getTime().toUnix() and (1'i64 shl 32 - 1)) # unixTime mod 2^32
rng.seed(seed)
echo "test_fp6 xoshiro512** seed: ", seed

# Import: wrap in field element tests in small procedures
#         otherwise they will become globals,
#         and will create binary size issues.
#         Also due to Nim stack scanning,
#         having too many elements on the stack (a couple kB)
#         will significantly slow down testing (100x is possible)

suite "𝔽p6 = 𝔽p2[∛(1+𝑖)] (irreducible polynomial x³ - (1+𝑖))":
  test "Squaring 1 returns 1":
    template test(C: static Curve) =
      block:
        proc testInstance() =
          let One = block:
            var O{.noInit.}: Fp6[C]
            O.setOne()
            O
          block:
            var r{.noinit.}: Fp6[C]
            r.square(One)
            check: bool(r == One)
          block:
            var r{.noinit.}: Fp6[C]
            r.prod(One, One)
            check: bool(r == One)

        testInstance()

    test(BN254)
    test(BLS12_377)
    test(BLS12_381)
    test(BN446)
    test(FKM12_447)
    test(BLS12_461)
    test(BN462)

  test "Squaring 2 returns 4":
    template test(C: static Curve) =
      block:
        proc testInstance() =
          let One = block:
            var O{.noInit.}: Fp6[C]
            O.setOne()
            O

          var Two: Fp6[C]
          Two.double(One)

          var Four: Fp6[C]
          Four.double(Two)

          block:
            var r: Fp6[C]
            r.square(Two)

            check: bool(r == Four)
          block:
            var r: Fp6[C]
            r.prod(Two, Two)

            check: bool(r == Four)

        testInstance()

    test(BN254)
    test(BLS12_377)
    test(BLS12_381)
    test(BN446)
    test(FKM12_447)
    test(BLS12_461)
    test(BN462)

  test "Squaring 3 returns 9":
    template test(C: static Curve) =
      block:
        proc testInstance() =
          let One = block:
            var O{.noInit.}: Fp6[C]
            O.setOne()
            O

          var Three: Fp6[C]
          for _ in 0 ..< 3:
            Three += One

          var Nine: Fp6[C]
          for _ in 0 ..< 9:
            Nine += One

          block:
            var u: Fp6[C]
            u.square(Three)

            check: bool(u == Nine)
          block:
            var u: Fp6[C]
            u.prod(Three, Three)

            check: bool(u == Nine)

        testInstance()

    test(BN254)
    test(BLS12_377)
    test(BLS12_381)
    test(BN446)
    test(FKM12_447)
    test(BLS12_461)
    test(BN462)

  test "Squaring -3 returns 9":
    template test(C: static Curve) =
      block:
        proc testInstance() =
          let One = block:
            var O{.noInit.}: Fp6[C]
            O.setOne()
            O

          var MinusThree: Fp6[C]
          for _ in 0 ..< 3:
            MinusThree -= One

          var Nine: Fp6[C]
          for _ in 0 ..< 9:
            Nine += One

          block:
            var u: Fp6[C]
            u.square(MinusThree)

            check: bool(u == Nine)
          block:
            var u: Fp6[C]
            u.prod(MinusThree, MinusThree)

            check: bool(u == Nine)

        testInstance()

    test(BN254)
    test(BLS12_377)
    test(BLS12_381)
    test(BN446)
    test(FKM12_447)
    test(BLS12_461)
    test(BN462)

  test "Multiplication by 0 and 1":
    template test(C: static Curve, body: untyped) =
      block:
        proc testInstance() =
          let Zero {.inject.} = block:
            var Z{.noInit.}: Fp6[C]
            Z.setZero()
            Z
          let One {.inject.} = block:
            var O{.noInit.}: Fp6[C]
            O.setOne()
            O

          for _ in 0 ..< Iters:
            let x {.inject.} = rng.random(Fp6[C])
            var r{.noinit, inject.}: Fp6[C]
            body

        testInstance()

    test(BN254):
      r.prod(x, Zero)
      check: bool(r == Zero)
    test(BN254):
      r.prod(Zero, x)
      check: bool(r == Zero)
    test(BN254):
      r.prod(x, One)
      check: bool(r == x)
    test(BN254):
      r.prod(One, x)
      check: bool(r == x)
    test(BLS12_381):
      r.prod(x, Zero)
      check: bool(r == Zero)
    test(BLS12_381):
      r.prod(Zero, x)
      check: bool(r == Zero)
    test(BLS12_381):
      r.prod(x, One)
      check: bool(r == x)
    test(BLS12_381):
      r.prod(One, x)
      check: bool(r == x)
    test(BN462):
      r.prod(x, Zero)
      check: bool(r == Zero)
    test(BN462):
      r.prod(Zero, x)
      check: bool(r == Zero)
    test(BN462):
      r.prod(x, One)
      check: bool(r == x)
    test(BN462):
      r.prod(One, x)
      check: bool(r == x)

  test "𝔽p6 = 𝔽p2[∛(1+𝑖)] addition is associative and commutative":
    proc abelianGroup(curve: static Curve) =
      for _ in 0 ..< Iters:
        let a = rng.random(Fp6[curve])
        let b = rng.random(Fp6[curve])
        let c = rng.random(Fp6[curve])

        var tmp1{.noInit.}, tmp2{.noInit.}: Fp6[curve]

        # r0 = (a + b) + c
        tmp1.sum(a, b)
        tmp2.sum(tmp1, c)
        let r0 = tmp2

        # r1 = a + (b + c)
        tmp1.sum(b, c)
        tmp2.sum(a, tmp1)
        let r1 = tmp2

        # r2 = (a + c) + b
        tmp1.sum(a, c)
        tmp2.sum(tmp1, b)
        let r2 = tmp2

        # r3 = a + (c + b)
        tmp1.sum(c, b)
        tmp2.sum(a, tmp1)
        let r3 = tmp2

        # r4 = (c + a) + b
        tmp1.sum(c, a)
        tmp2.sum(tmp1, b)
        let r4 = tmp2

        # ...

        check:
          bool(r0 == r1)
          bool(r0 == r2)
          bool(r0 == r3)
          bool(r0 == r4)

    abelianGroup(BN254)
    abelianGroup(P256)
    abelianGroup(Secp256k1)
    abelianGroup(BLS12_377)
    abelianGroup(BLS12_381)
    abelianGroup(BN446)
    abelianGroup(FKM12_447)
    abelianGroup(BLS12_461)
    abelianGroup(BN462)

  test "𝔽p6 = 𝔽p2[∛(1+𝑖)] multiplication is associative and commutative":
    proc commutativeRing(curve: static Curve) =
      for _ in 0 ..< Iters:
        let a = rng.random(Fp6[curve])
        let b = rng.random(Fp6[curve])
        let c = rng.random(Fp6[curve])

        var tmp1{.noInit.}, tmp2{.noInit.}: Fp6[curve]

        # r0 = (a * b) * c
        tmp1.prod(a, b)
        tmp2.prod(tmp1, c)
        let r0 = tmp2

        # r1 = a * (b * c)
        tmp1.prod(b, c)
        tmp2.prod(a, tmp1)
        let r1 = tmp2

        # r2 = (a * c) * b
        tmp1.prod(a, c)
        tmp2.prod(tmp1, b)
        let r2 = tmp2

        # r3 = a * (c * b)
        tmp1.prod(c, b)
        tmp2.prod(a, tmp1)
        let r3 = tmp2

        # r4 = (c * a) * b
        tmp1.prod(c, a)
        tmp2.prod(tmp1, b)
        let r4 = tmp2

        # ...

        check:
          bool(r0 == r1)
          bool(r0 == r2)
          bool(r0 == r3)
          bool(r0 == r4)

    commutativeRing(BN254)
    commutativeRing(BLS12_377)
    commutativeRing(BLS12_381)
    commutativeRing(BN446)
    commutativeRing(FKM12_447)
    commutativeRing(BLS12_461)
    commutativeRing(BN462)

  test "𝔽p6 = 𝔽p2[∛(1+𝑖)] extension field multiplicative inverse":
    proc mulInvOne(curve: static Curve) =
      var one: Fp6[curve]
      one.setOne()

      block: # Inverse of 1 is 1
        var r {.noInit.}: Fp6[curve]
        r.inv(one)
        check: bool(r == one)

      var aInv, r{.noInit.}: Fp6[curve]

      for _ in 0 ..< 1: # Iters:
        let a = rng.random(Fp6[curve])

        aInv.inv(a)
        r.prod(a, aInv)
        check: bool(r == one)

        r.prod(aInv, a)
        check: bool(r == one)

    mulInvOne(BN254)
    mulInvOne(BLS12_377)
    mulInvOne(BLS12_381)
    mulInvOne(BN446)
    mulInvOne(FKM12_447)
    mulInvOne(BLS12_461)
    mulInvOne(BN462)
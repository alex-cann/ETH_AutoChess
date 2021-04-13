// SPDX-License-Identifier: LGPL-3.0-only
// This file is LGPL3 Licensed
pragma solidity ^0.8.1;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        uint256 pt1zx = 1;
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
        }

        uint256[6] memory pt2 = _ECTwistMulJacobian(
            s,
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            pt1zx, 0
        );

        return _fromJacobian(
            pt2[PTXX], pt2[PTXY],
            pt2[PTYX], pt2[PTYY],
            pt2[PTZX], pt2[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Add(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            addmod(xx, yx, FIELD_MODULUS),
            addmod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Div(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX], pt2[PTXY],
                    pt2[PTYX], pt2[PTYY],
                    pt2[PTZX], pt2[PTZY],
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy);
            }
            (
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            ) = _ECTwistDoubleJacobian(
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            );

            d = d / 2;
        }
    }
}
// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return r the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2) internal view returns (G2Point memory r) {
        (r.X[0], r.X[1], r.Y[0], r.Y[1]) = BN256G2.ECTwistAdd(p1.X[0],p1.X[1],p1.Y[0],p1.Y[1],p2.X[0],p2.X[1],p2.Y[0],p2.Y[1]);
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

library Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x1936c240636390dc823e3a728e94b208eb53c6756d81da57ec3425e05d43ac10), uint256(0x2d70ff78e8216bf29d58923a686d9738278b8ce2fd822e197c85b09286d15566));
        vk.beta = Pairing.G2Point([uint256(0x29c13ecb6f33dbc4b3b8a02e2e255511ce4c26a8a2f299efcc94caf2de4fce00), uint256(0x2b4daf047abe2e7f0b311118c1b963b63695dc0d769cea78849604434de055bf)], [uint256(0x25ea0d7e2b29de431b86a943db30dbf4d98f68df9ca8a9628d14d1591e817d90), uint256(0x1da9020008df7f549751f8a251af3b2dc4a2ad3e0870de54acaedd9fc1b47e17)]);
        vk.gamma = Pairing.G2Point([uint256(0x00e83c788c2878d1d5eba3ed49b0d81e4c0487dedc3e4d1c2baab5833785b62f), uint256(0x011016e22ae045444f50fb80f246ec486c7e02af09132cd38c4fcf484983e4f2)], [uint256(0x132a90a3b0d369ccd66e2a5ba04a935e44d8ad5dca93a76bba592a578130a911), uint256(0x05eb89e741ed5b5d611cebf92d1ed02cd6f3311089f0d400df7d9ced5a48fd41)]);
        vk.delta = Pairing.G2Point([uint256(0x0c3b60f59d3bd50328a04c0ff6d979199685d0526f89f6ac29d6174ce24707a2), uint256(0x065f6a3323a2abffd621fc263f348eb914904b68d5897729ae34a6b9d33f0852)], [uint256(0x12e0f3721230a0f38f6c9913048d5230fd2615ef3ff7f6ee4b20dfe0bdea1a86), uint256(0x26e7ebce2b44efef6b6315938e33f0a8ecc82dbad635c9efa681ed85bbb59982)]);
        vk.gamma_abc = new Pairing.G1Point[](45);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x11d61ba810b75b111c8cb3a6a30ce3375c442da9f17a6f3174e690b0ba9375ed), uint256(0x1270e192b15af163f64bfd3939cd0e0e526e2fc082a7ae6052dfed2c705c4d90));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x285af8995ea42589abc59724928f6b603e59fbcad7c9db3d9b1fd4e4e962054e), uint256(0x170c2beb14ad580a404cb2871a1ee49680d23485ad8954412f60a09982c902d3));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x1f571ccfe22b866717198412f40c648ecf37357321abd8f1c21223426f089417), uint256(0x17d7ed466be9104ef5f60b9a31909cf8f141ff060381f54a50be229e87f89968));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1fc56e7fd93b20ed5108834bc4739fd25e43e6183b2af64eaf55dc648890f7cd), uint256(0x0f646159a1df9f38b1d0177723e1784d2bad691d5b809c65e15f9b99bfb07d6a));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x25049a5634bba5f2008472c2156d72d773b0e321901cc029bae44147f4c6aac6), uint256(0x0c28e2f1635d996ef69750854f75d21d2d111befbf1458c5be70d7906774f526));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2163fc55cefa9fa82b169e1f54b4c407e4b68bb1841cba52b111d56f9fbb6c9b), uint256(0x18340fa57f6912781990be7f28012ffe1db62fde1df3464d09f47234edb2fa5e));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2a4c1cb1ebf6e0b39804426c40641291b8d237af1227865f19c290e4c227cd66), uint256(0x1bc2c961b27259be9ad2c7fe57350c892be1fde2f2014512b6db3dabb47cd76f));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x06ac0238db3084e7dbc8c82be33706906cdc6193c135693e7d7584bc08aecda4), uint256(0x09a20fbd7c0f311288f695cdeaa2b7566eca12e32360fb037a9c6c77ea003ef6));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2b5ad6769e14f022d0a16507f81566dbe18ab1bb78a0f649d493f97255e173e8), uint256(0x238e2c9fb05cbf564c1e317b61c0de7742d27bd0927d1fba5649b06ded932978));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x25cb7d8439221ce128f1a1aa5ed9c95c1b05a541b01b8a431a86a3e33ed68e9e), uint256(0x073cc02780cca076492bbc0b092ce32022bfd3e2450ca04a33a4a94782d5f2ea));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1a0278ebfe91798d67674fa87ad740b98401d1c9494daf5c8089c8e7121dbb8d), uint256(0x02e6b0c0cbdbd59fb42ca419db3ef703a3da392147704909b5a0e872dd899464));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x21780e91d52afb209419dd17f6599aa38a52ddc8e1e5f49ed6090e7c4d03b3fe), uint256(0x22a80c546a26ca0d8f8fe8257c9991926b191f3f3dba0bd90fda786c39c37b91));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0bb2397a6c30c72f48b0c72c0f5577534699f6ea7cf67c490742c1c9e17b6cc7), uint256(0x11862760eb0a0abd05d4e7881cc240156bec95492edb5fc8aea0aec3ec29c9ec));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2407c52455d258d61bd1e90bb54813e978040b02df5f030a30ee077eb07ea964), uint256(0x05b61262fb1231689b1a643d60c428c4cb9c63a255e08de66f722596ec1d1e5c));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x18a82ed3da6e9e51077ba90e9ba567336b82f901ffbe1f6c1f3e41797f7bea30), uint256(0x0dfedb55a5a958c52b7ca38c87373fecb39e8e8756743fb5ed961464424c120e));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x158d95fac4a0e988afafc590d18a595f03d13521296a8f7d05f04b39d567370b), uint256(0x005b73f2e6187340e22dd80ba9a6fb498e165253770930ab716a1b60cb91a4c1));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x17d02024f43b1c743b7733c6e43002f871d6c6ed43b6a20f3a75a73ad4a2580a), uint256(0x000b6780be16a45e6ac0e196d50a6e9a4820afa6602126c1a7ab2668ec9e186e));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x25db7771c4b3349e3fcb86d8eb554207ac29eaf7d70e907193fd9074ef4f0ebb), uint256(0x0dd75c6391f014aefb0ba76cb9c789dba910d30c91c1732084c0d812309a1cc8));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x0e7e5b8029abc3506d6b811cc7946c63b6e2a6e01809044bf4f6f9430148aeac), uint256(0x268471fe70289f7fe4a7705b6c0d431139206a4d492e4136eb9f6f55c6f8bc2d));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x1576bf986f9bb210466b89b873a7833269b050848d332c99ba608f1eaee6aa01), uint256(0x1168485516689926c4b2a4b673707f4942b8dd6f402ec95f1ee907f2a3d84577));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x0f650e71d6129969855f8a5a3127c78efb4861cf962453121394d7efcfcbd664), uint256(0x156cd8241fe65924bfdf5a2310f56336be40fbacfd5123bbfa7a769a10249e67));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x1720661c8da5778c83feafdd22eb41b9e254b046d5b949150c40278eda51cac8), uint256(0x2b345b2ee888e683c0157b13d53d3088f0875013bc3d14e25ed3781b703950a9));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x06a42e8b89d8a954f0f7e91aa0c8b98e693592decf4201fd4a06e24e3bfb5002), uint256(0x1c7dab7f0ea42bdd88dd17122095541c417a99458fd68d4f97093520d8a883d1));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x2f10e0f4309d454904b1227d28487f10c1f85de7fcf61f5ea631d6fc8281a544), uint256(0x28b62b01d02d2a0032f1a5aba9d53cc0687db89002af71da7c0d402fac3e1993));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x2d403f9337d943df284d0b53f2bf9bcc780d914cf9e1247b45586c074184dc21), uint256(0x2a1bd2010162e162342bb6600c58584aa7118872f38508b43d578d5c0e6c17e1));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1c46a154826c6121308dc486196ca41603bd50339530314e38eb2739f7e1e692), uint256(0x08c06598e305c986293fab4a0cf6b96aed0a6fb59be6963ea97333f61c87e34e));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x135e0e2528bd615b25fb503e6088524dbea76b0fc3fba9cd52cc39a7fbcda336), uint256(0x0994ffe326c29ea1933d509d45f3a6ac413c0e2fcf92d35e3e6a549f6e2e30fd));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x17a5afe6d0290b06964489d3d602e42eb59af1de66a8b35904efd8f52a53fd94), uint256(0x08c49705a396be50d841b1541cfd51ad384641f03cd61966b37e2550a1e95987));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x26de9f6db72a741bdd305198ea0445e47184ebfe4b92e75045e58dda24d86c6d), uint256(0x23c5c3e0305866f134fb5c6a573e5be97295f028282325565ef20f938067fa03));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x162975a783b65e6a6fb30c732fe961a96bf1eb7eb3685abc84b53ff11abf329a), uint256(0x0478aeb0f705e43d0942b7c1885af3bfc801f1abd180b073a39de5c8b461cf47));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x2e5fd2013c2b13fa019a83cbd3f43d7938461e4c9e5552eb9017b32fc34e8bf3), uint256(0x0e349dade08115db3519733364205d90fb59a7e6eef1bc581f166668df10ae60));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x126e12d37fbad5cc47820cee2474394db82d925f3264563e8e1c1a0b03cb5841), uint256(0x28a711671bf925d68ce783d93b94b68775f6d69a847fb47f7af61700baadf66f));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x2a6f1b2021a6ae3f7fac4887914e19534643bba2bd9ce4c2edbf24542e381312), uint256(0x1e909b208d46c4eb0714792327f38a3b3e3c9350f14de68301476546af6814c6));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x17731ef02b08f468114b1ccc76537249108306faee4e4b0d2dd708f5295bd427), uint256(0x23f0f6cb589e2f90e34acb7eac32add32987f06bfc667e99b55a7c0538f33a4d));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x1b31b04d5091e77c36ee687cfc452d394a4a075d0a1b45e8b573d8149357a8bc), uint256(0x295f3fa7b71bf3ff983d32791ed3b30b1b465616095336b32f7b8d1ac4a3d451));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x1263c668033c68e46dec13c6d485daf75ed91a0bfa9850bf328106d1d955970f), uint256(0x0e2b89cdd17582d9dd732ad91971541a95aa61f78feb4f43d562b75fa7b80acb));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x0afacb52e45d8a85bdc35081c35ac602ca40d64ef0f58ca91e370ba5f540a1c0), uint256(0x06e0e6ad986020bc70cde21d2b78618b4fe7a6fd97bfe7a0079fe3eccce2d492));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x0713bb6e5c0f353645da92e86e9892072c71816615a09baa9c6a9d783ef5befd), uint256(0x182838bee668d2a05a6a049fa6f7fad4593bb43005187f36a9b82f870a4e05ac));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x148f3718c087f6ec736055d15b923c4b9c0f93d67d64d43cb085ef207aeb28ec), uint256(0x0235f9abc5fa835a3c10cd2c7bbd45cca9c4adb679770cc6dd074887e4cabf95));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x26082ea9e67339be7a3901c4d2af05cb822967212e3ade94f9da2d80b98192c3), uint256(0x060f244151e628bb6077a67b555b523ffbca5a31308807f1180d6d0553437435));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x0996398eff35ce28ac4189979cc0644e88819e6d6403524d1caf5ba175e0869a), uint256(0x13d9fa61308b6454de3f489f5d2de44545755f60848473fb845357410874838d));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x16b4ce0c2d293168e8730f6730ca7002c23b5341a8a66d858389e47bbd0ad796), uint256(0x27517ee760585473fc200b5e900cb7f6b845d916e3b3ffa1f724452e26c2fd32));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x149417d7e7c0e43d0ad34a92df1d22a7113858f3378ad3eabedf4396699475cd), uint256(0x1ff8712353217c4dfedc9a38bdce591c8f6adcb5200f23a3073e665e9d976500));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x0c39b606db9740c2a42111aac5b68ad2f7e4953452183628ae9548b25fa2c890), uint256(0x2aaf9cce0d18e28ff55632d946884cff256ddd9cc92d927fa462964b2d61a356));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x04da530427c4adf2a10b2708a193096f71d3d7f4e4e880e9bae13341ab182f54), uint256(0x0c20a057490a7bc04d1cb9fbc226caf83a62ac8ffb75dd268e76bea3d3110717));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c, uint[44] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](44);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

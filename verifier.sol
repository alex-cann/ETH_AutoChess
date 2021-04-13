// SPDX-License-Identifier: LGPL-3.0-only
// This file is LGPL3 Licensed

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
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1c2faf9df9ce339474c9b7c5c30646eb71603d750ec1774f3711a918d10d44b7), uint256(0x1d547f874320dd42a71a2228bc4fa1d8505231f6ed43c04a390918eb3640d838));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x273881b3125e77789e147221c9f49303ad16897bdef0788add1bdf3c9b7151f3), uint256(0x224d1e34517e56c6bdd670461c581e60146174759dcd7d64162610c162bf5422));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x16a081f07f1cfd666670ffe9c7daf78d7fa8d9acf3d7756c420cd41184c69783), uint256(0x0220f37229313a1cff55154bdfb234779187a5692ab1357c84024752ef95f580));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x21b7dd2fe07a5ef2e4f2f950a84259664c7b970f7b9c9cc5444b959f5e29b435), uint256(0x2d82eba6973cfafa028decdfe46147b7b386fa595cf2f4654395a08f3c1a5a97));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x26ca61b4c267957460abf63f894d04341ca9ad50dd944c7a9c92822951a071f4), uint256(0x1d8c2698ac361c2180788232be732b00535553d4640ba42fc39732fbd193437e));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0204a42f220d4b0774ae26af28464636b03a24d70be9ebcb436853dc340cfba5), uint256(0x0c30a5bee6edf1e30d75a843c96285d9da79869034822cd24d4dabc31d9ace59));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x204b869adfcac1b43d519f950fb79fe56468e09b352917bee007f1778b88abeb), uint256(0x05f6b29ccae0580bb8542156af899b40b32f33a682784335575d71b695cb3606));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x24244240d136687296a576f426b2503849b109a78b5b6d9bf0624f83ae98800e), uint256(0x1d6c243ed5bddecbe1bd272179576594842bae0b5008ecb12c9e43fd499e8430));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x09115f2f9dc7f8ab47abb8f1d2bf2e7fbdcb34817fbe92ae39810aaf2078f196), uint256(0x01c9f3c3d3204664744e13a7d59616e9f830207ff285efffd08e05fd6a8e5cae));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x076e4b117bb45d4d2450b262e5a72a676b85cc9316aeb9715ce202e487647616), uint256(0x1efdb211d046148a17c3c23fc27bed53b809e4c4ce82e119bae513627d5da6d4));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x19ffb856d92e98038b8691c1b996b75ad17449d47208f6c23e9ea13faa7d556a), uint256(0x0589574b678f20da7c1de4d1b48e38b02ea3c81acdd6bc52a045c8425b0ae590));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0b9f5f172ae18443d37670a33c39be189a9910f7f857af61e368a902faad1407), uint256(0x038e2e6f5ef16cfba39c7dbf47774792ab052ff7a92e55a61492f2c48ff32047));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x233cbcad99e37a29017e11d5d8f3d0f8da05ffa9a253e23f5c9a7ed72613f355), uint256(0x1a18f9c2b6a46a000cdd2ee0447ea3d82295f3073559b2d3b5dcd7b166e14552));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1fde96b214ea28bf91fbe3920029a8c5c0a6c665e2981ceebe1576b1cb06c733), uint256(0x30439df18e90237e60300925a870d0fd9f0cce38285824d849057fcb8ec6062d));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x192f4d49b5cd3050a00e2a706264e1386a45fb786bec0846c0fb6a42f13a21b4), uint256(0x12e505c73e8ddae587fbdb56833abca9ef1ce9a154fc0649677941edb6a5cc57));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2138fe34068ff29721511b35c6c290ed16eacd8d936b3f7d8d76081c7749af3d), uint256(0x2fe2a69caca1eb49191377506365f4994c46afcbfd1a876c3f789d91bf554488));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x07c6c17c7fa2d42375caa31cbde99a8b466239d2c4a0cc8856d884d87cf3840a), uint256(0x186980d3bd863b94327ca8abbc209c130ecf9a3c5a92737f9082ba55e4dd96f4));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x15aea64c4c31da420368890d4d3b999a0978707c272c3f155bf894cc8393e08a), uint256(0x26f9f3410cef69108d89c6b92c8a76aea6ddc3b9cefb69f43964fbb800183090));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x2ab42d8f51681cdc867d065d521a3ef33948ddcab12f0a0f7c8534fff2161a3c), uint256(0x2b5e2d3bc865234acb0fe92996fc7952dccc5ed0905f508af82c2a5892825a2b));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x1b8415aeb2caff64cf0c7cec05c72734aa4b10b8401d5cf033d94ffbd8c86590), uint256(0x19548b9ef4ae1b1235c1f151e68894f5207b4a94cad08fb48e782fb1c7ce59e3));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x09373744671b92f34b6390bcd058cbd3c0342e531f49ce915a38926f785e6322), uint256(0x220ce67f696b5c77b406776b26b42147edba1d288a3b70e98cc2ce8bc8774a8e));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x2b114ebb1990a917f74a15d454583a017a626a84be635efa0a5414218d31d11c), uint256(0x15a0e1a6af1f6b7e4049b9815f18c1b43654153fdc19e6c1978e491cad9ea2ce));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x1d73f0ceae0da6b7b3e7c602e9d63b95d1ebe89f06a169f79347b08d94ec2aa7), uint256(0x2ad8819ca7f4e8478254ac061f231c9883b56695e21ac36326c7825261c08fdc));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x2779e12a34bd2350a293ba7394d4cb06beabb0f4d312d80b59beb2a4b1d0eaa0), uint256(0x055a009f2c070501ddfd2ac54eea1dc7588ebf3bb742afc23f7e33f35c579bbb));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x2b219915447e5fa78ac17ed42f26663396a81070bc7a0da41d08e1853b148411), uint256(0x012e043333920283d9c8af63f5c5e2466dafe279faedc1b910c2fe441ecf856c));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x2dbbd56899c54ec9abfc51b843b128988491f55ba2054b6bc9c16821075d6a23), uint256(0x1392e36bf076d42198129f60bc74631a1857d91ecf6e8708609d5341a4f08cf1));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x188afa17d0eb0debb05562e30142fc012fa253079ebaf0d1d372a636466a75f3), uint256(0x10e5428db42ac8b459475d6f6533b0b654cd31bb28de3fb2bbd569661f62faae));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x0ca4cddad84ae5e2b1a5ac8a2437ee023db3a62fe51442fd290fa79081e95687), uint256(0x0c523e68a8f5e24ee19e6c6d97b4814e51aa77bec4ee833b996aea67f228293e));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x12af58c21686e9bdd2f5aaa0e22c47310e1055e1cc2559a9562c5e1607b9ef7b), uint256(0x0e2ac559b560f0c6162a58abcd6d996e72c452fd7c772c627ba10c8f098ec679));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x1ab9cda41948b456086c54af96e343ec97b19482abe02a34b0e6eb2273db381f), uint256(0x203b020a508022ed5f22bb91220f7e1566f5c2430a1c22fe28632c26f8eee42b));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x0dbc9aaf10cd73cbf6c05474ad0ae37c8b9bea5b4b5be318649d161fdf52238d), uint256(0x039c7baba03bc77a90b4a93251507a52a6ace3afd5bef5765d88986b873051b7));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x000add961cde3bcc52ca730eee9e19760bbb79f3b713b254d0e14f39240abc3c), uint256(0x256d6f38c28973213ed82c9aa8ca4593c92d4f77967f1ffe3cc5cd1dea693dbb));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x08776871f238e035902adbdf98b76fef66aca91b90923bb53ec6a45491557eae), uint256(0x06620892632adf3fb047b050d63c1040c126a0739e19ddd88d7edf60afebda86));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x2d14018262290b54a6294279059f9f2d9c01503f7f6f1040edb3a9920852a1ae), uint256(0x100a153943376ad5b4ea1bfdb53c6b900ee625787f95de54eec474c9ad16bcad));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x00f5c9c90e08017ee0969563e460e674e72f05b7ad0381ebcdaf604a51d77007), uint256(0x133a434392ea93da3a50831410ebdd18ef16dad3d8ceb1535738c7f9090446b7));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x035d14d72a173d0bf727418a3c8b6dd00f20cecf970d92a5cb8bd2d6290541ae), uint256(0x1b176f2bf8691e21d9dfa7207e9cd1bfc456e95059df67ab9597b2d335afc0a7));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x13865b29935c83de2b79a8cc85e0e99147fc0a23a8eac921da47ae89421265fc), uint256(0x186fd2bfc2fae7a7b7c6d6baf94b5ba84f31b5a23875a66df54234cb7fb4982b));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x0b47da68cf6749df49fa98a08463a4641c1a0e6dae7b63e7b4fcd3413bd35f11), uint256(0x1bf4f4fa03246b61a8107a3fb9b9d51dca757453001bafee95255fdcadeedc7b));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x1c1f56be046fc9e33d6eb6031aba7ad69c6ac7692b8d4cefa8bcf63afd2eb4f9), uint256(0x001162756f095dfea3bc14f24e9b6800ad93042ddf48804aa9841c4459323d4d));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x130341c7e3f06b2c35020cdb837b7315b16a798d4876bbbe47a252b591ad29e6), uint256(0x2f61880a8eacd7d3107030609b7ba173ae1880871b5bdb6b7e0eadb4ee106e4e));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x2582e45ee3221a2f88e18c3c14d79eaef54d8159789a3aa70e69cba409ac017c), uint256(0x0362ad8dd148be4a0c56dafb7331fb7a3c76cdf33a9a4d337e27124babfed7ec));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x195ad02603c7bfa685a0f65907ec208400fc558eed4624b490df9b74124cabb2), uint256(0x24ff3092e70d569b3f322244689b1a2deb252b0e6cdf9198728441d4d8df4a62));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x007cd763be3301ffd15cc978ce3e975c2bb9c336910bc584e16ce3abe3dba194), uint256(0x219c03c22c6f853cc15ab2f33175ce564c54b0ab1a7c1fc06a5901cbcbd3d33a));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x168ef84235228aa771b2b4627c96206cee084133c23f0f2be07646cf133adfd8), uint256(0x0de8301b1af69e700ad0010ef1e846601c8e4be03f71c81760d4115a99335255));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x178c6c7ef03e971a2b4eee32d9a5a1cc3f4817fe89169b816fe3c2b55e947ffe), uint256(0x04b07436afbeeb9c2841764ee845b261cf1517dbe77bf41415aba6c0c28b2e1d));
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

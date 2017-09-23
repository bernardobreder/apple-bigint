//
//  BigInt.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2015-12-27.
//  Copyright © 2016 Károly Lőrentey.
//

public struct BigInt {

    public typealias Digit = BigUInt.Digit
    
    public var abs: BigUInt
    
    public var negative: Bool

    /// Initializes a new big integer with the provided absolute number and sign flag.
    public init(abs: BigUInt, negative: Bool = false) {
        self.abs = abs
        self.negative = (abs.isZero ? false : negative)
    }

    /// Initializes a new big integer with the same value as the specified integer.
    public init<I: UnsignedInteger>(_ integer: I) {
        self.init(abs: BigUInt(integer), negative: false)
    }

    /// Initializes a new big integer with the same value as the specified integer.
    public init<I: SignedInteger>(_ integer: I) {
        let i = integer.toIntMax()
        if i == IntMax.min {
            self.init(abs: BigUInt(IntMax.max) + 1, negative: true)
        }
        else if i < 0 {
            self.init(abs: BigUInt(-i), negative: true)
        }
        else {
            self.init(abs: BigUInt(i), negative: false)
        }
    }

    /// Initializes a new signed big integer with the same value as the specified unsigned big integer.
    public init(_ integer: BigUInt) {
        self.abs = integer
        self.negative = false
    }
}

extension BigInt {
    /// Initialize a big integer from an ASCII representation in a given radix. Numerals above `9` are represented by
    /// letters from the English alphabet.
    ///
    /// - Requires: `radix > 1 && radix < 36`
    /// - Parameter `text`: A string optionally starting with "-" or "+" followed by characters corresponding to numerals in the given radix. (0-9, a-z, A-Z)
    /// - Parameter `radix`: The base of the number system to use, or 10 if unspecified.
    /// - Returns: The integer represented by `text`, or nil if `text` contains a character that does not represent a numeral in `radix`.
    public init?(_ text: String, radix: Int = 10) {
        var text = text
        var negative = false
        if text.characters.first == "-" {
            negative = true
            text = text.substring(from: text.index(after: text.startIndex))
        }
        else if text.characters.first == "+" {
            text = text.substring(from: text.index(after: text.startIndex))
        }
        guard let abs = BigUInt(text, radix: radix) else { return nil }
        self.abs = abs
        self.negative = negative
    }
}

extension String {
    /// Initialize a new string representing a signed big integer in the given radix (base).
    ///
    /// Numerals greater than 9 are represented as letters from the English alphabet,
    /// starting with `a` if `uppercase` is false or `A` otherwise.
    ///
    /// - Requires: radix > 1 && radix <= 36
    /// - Complexity: O(count) when radix is a power of two; otherwise O(count^2).
    public init(_ value: BigInt, radix: Int = 10, uppercase: Bool = false) {
        self = String(value.abs, radix: radix, uppercase: uppercase)
        if value.negative {
            self = "-" + self
        }
    }
}

extension BigInt: CustomStringConvertible {
    /// Return the decimal representation of this integer.
    public var description: String { return String(self, radix: 10) }
}

extension BigInt: ExpressibleByIntegerLiteral {

    /// Initialize a new big integer from an integer literal.
    public init(integerLiteral value: IntMax) {
        self.init(value)
    }
}

extension BigInt: Comparable {
    /// Return true iff `a` is equal to `b`.
    public static func ==(a: BigInt, b: BigInt) -> Bool {
        return a.negative == b.negative && a.abs == b.abs
    }

    /// Return true iff `a` is less than `b`.
    public static func <(a: BigInt, b: BigInt) -> Bool {
        switch (a.negative, b.negative) {
        case (false, false):
            return a.abs < b.abs
        case (false, true):
            return false
        case (true, false):
            return true
        case (true, true):
            return a.abs > b.abs
        }
    }
}

extension BigInt: Strideable {
    /// A type that can represent the distance between two values of `BigInt`.
    public typealias Stride = BigInt

    /// Returns `self + n`.
    public func advanced(by n: Stride) -> BigInt {
        return self + n
    }

    /// Returns `other - self`.
    public func distance(to other: BigInt) -> Stride {
        return other - self
    }
}

extension BigInt: SignedNumber {
    /// Negate `a` and return the result.
    public static prefix func -(a: BigInt) -> BigInt {
        if a.abs.isZero { return a }
        return BigInt(abs: a.abs, negative: !a.negative)
    }

    /// Subtract `b` from `a` and return the result.
    public static func -(a: BigInt, b: BigInt) -> BigInt {
        return a + (-b)
    }
}

extension BigInt: AbsoluteValuable {
    /// Returns the absolute value of `x`.
    public static func abs(_ x: BigInt) -> BigInt {
        return BigInt(x.abs)
    }
}

extension BigInt: IntegerArithmetic {
    /// Explicitly convert to IntMax, trapping on overflow.
    public func toIntMax() -> IntMax {
        return negative ? -IntMax(abs[0]) : IntMax(abs[0])
    }

    /// Add `a` to `b` and return the result.
    public static func +(a: BigInt, b: BigInt) -> BigInt {
        switch (a.negative, b.negative) {
        case (false, false):
            return BigInt(abs: a.abs + b.abs, negative: false)
        case (true, true):
            return BigInt(abs: a.abs + b.abs, negative: true)
        case (false, true):
            if a.abs >= b.abs {
                return BigInt(abs: a.abs - b.abs, negative: false)
            }
            else {
                return BigInt(abs: b.abs - a.abs, negative: true)
            }
        case (true, false):
            if b.abs >= a.abs {
                return BigInt(abs: b.abs - a.abs, negative: false)
            }
            else {
                return BigInt(abs: a.abs - b.abs, negative: true)
            }
        }
    }

    /// Multiply `a` with `b` and return the result.
    public static func *(a: BigInt, b: BigInt) -> BigInt {
        return BigInt(abs: a.abs * b.abs, negative: a.negative != b.negative)
    }

    /// Divide `a` by `b` and return the quotient. Traps if `b` is zero.
    public static func /(a: BigInt, b: BigInt) -> BigInt {
        return BigInt(abs: a.abs / b.abs, negative: a.negative != b.negative)
    }

    /// Divide `a` by `b` and return the remainder.
    public static func %(a: BigInt, b: BigInt) -> BigInt {
        return BigInt(abs: a.abs % b.abs, negative: a.negative)
    }

    /// Adds `lhs` and `rhs` together. An overflow is never reported.
    public static func addWithOverflow(_ lhs: BigInt, _ rhs: BigInt) -> (BigInt, overflow: Bool) {
        return (lhs + rhs, false)
    }

    /// Subtracts `rhs` from `lhs`. An overflow is never reported.
    public static func subtractWithOverflow(_ lhs: BigInt, _ rhs: BigInt) -> (BigInt, overflow: Bool) {
        return (lhs - rhs, false)
    }

    /// Multiplies `lhs` with `rhs`. An overflow is never reported.
    public static func multiplyWithOverflow(_ lhs: BigInt, _ rhs: BigInt) -> (BigInt, overflow: Bool) {
        return (lhs * rhs, false)
    }

    /// Divides `lhs` with `rhs`, returning the quotient, or trapping if `rhs` is zero. An overflow is never reported.
    public static func divideWithOverflow(_ lhs: BigInt, _ rhs: BigInt) -> (BigInt, overflow: Bool) {
        return (lhs / rhs, false)
    }

    /// Divides `lhs` with `rhs`, returning the remainder, or trapping if `rhs` is zero. An overflow is never reported.
    public static func remainderWithOverflow(_ lhs: BigInt, _ rhs: BigInt) -> (BigInt, overflow: Bool) {
        return (lhs % rhs, false)
    }
}

extension BigInt {
    /// Add `b` to `a` in place.
    public static func +=(a: inout BigInt, b: BigInt) { a = a + b }
    /// Subtract `b` from `a` in place.
    public static func -=(a: inout BigInt, b: BigInt) { a = a - b }
    /// Multiply `a` with `b` in place.
    public static func *=(a: inout BigInt, b: BigInt) { a = a * b }
    /// Divide `a` by `b` storing the quotient in `a`.
    public static func /=(a: inout BigInt, b: BigInt) { a = a / b }
    /// Divide `a` by `b` storing the remainder in `a`.
    public static func %=(a: inout BigInt, b: BigInt) { a = a % b }
}

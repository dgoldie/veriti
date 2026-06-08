defmodule Veriti.ValidationTest do
  use ExUnit.Case, async: true

  alias Veriti.Validation
  alias Veriti.OCR.Parser

  describe "valid_vin_checksum?/1" do
    test "returns true for known-good VINs" do
      # 1HGBH41JXMN109186 — check digit X at position 9, sum mod 11 = 10 → X
      assert Validation.valid_vin_checksum?("1HGBH41JXMN109186")
      # 1G1BL52P7TR115520 — check digit 7 at position 9
      assert Validation.valid_vin_checksum?("1G1BL52P7TR115520")
    end

    test "returns false for VIN with wrong check digit" do
      # Flip the check digit (position 9)
      refute Validation.valid_vin_checksum?("1HGBH41JXMN109180")
    end

    test "returns false for VIN with invalid characters (I, O, Q)" do
      refute Validation.valid_vin_checksum?("1HGBH41IXMN109186")
    end

    test "returns false for wrong length" do
      refute Validation.valid_vin_checksum?("1HGBH41JX")
      refute Validation.valid_vin_checksum?("")
    end
  end

  describe "validate_vin/1" do
    test "returns :pass for valid VIN" do
      assert {:pass, nil} = Validation.validate_vin("1HGBH41JXMN109186")
    end

    test "returns :not_found for nil" do
      assert {:not_found, _msg} = Validation.validate_vin(nil)
    end

    test "returns :fail for invalid checksum" do
      assert {:fail, _msg} = Validation.validate_vin("1HGBH41JXMN109180")
    end

    test "returns :fail for wrong length" do
      assert {:fail, _msg} = Validation.validate_vin("SHORT")
    end
  end

  describe "validate_title_number/2" do
    test "passes valid California 8-digit title number" do
      assert {:pass, nil} = Validation.validate_title_number("12345678", "CA")
    end

    test "fails California title number with wrong format" do
      assert {:fail, _msg} = Validation.validate_title_number("ABC12345", "CA")
    end

    test "returns warning for unknown state" do
      assert {:warning, _msg} = Validation.validate_title_number("12345678", "XX")
    end

    test "returns not_found for nil number" do
      assert {:not_found, _msg} = Validation.validate_title_number(nil, "CA")
    end
  end

  describe "detect_lien/1" do
    test "detects explicit lienholder mention" do
      assert :detected = Validation.detect_lien("FIRST LIENHOLDER: BANK OF AMERICA")
    end

    test "detects lien keyword" do
      assert :detected = Validation.detect_lien("There is a lien on this vehicle")
    end

    test "returns none when no lien keywords present" do
      assert :none = Validation.detect_lien("OWNER: JOHN DOE VIN: 1HGBH41JXMN109186")
    end

    test "handles nil gracefully" do
      assert :none = Validation.detect_lien(nil)
    end
  end

  describe "Parser.parse/1" do
    @sample_text """
    STATE OF CALIFORNIA
    CERTIFICATE OF TITLE
    VIN: 1HGBH41JXMN109186
    TITLE NUMBER: 12345678
    REGISTERED OWNER: JOHN DOE
    ODOMETER: 45,000 miles
    """

    test "extracts VIN" do
      result = Parser.parse(@sample_text)
      assert result.vin == "1HGBH41JXMN109186"
    end

    test "extracts state" do
      result = Parser.parse(@sample_text)
      assert result.state == "CA"
    end

    test "extracts odometer" do
      result = Parser.parse(@sample_text)
      assert result.odometer == "45000"
    end

    test "returns nil for missing fields" do
      result = Parser.parse("some unrelated text with no title fields")
      assert result.vin == nil
      assert result.title_number == nil
    end
  end
end

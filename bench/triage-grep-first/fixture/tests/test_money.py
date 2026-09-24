import unittest

from tally.money import fmt_money, parse_cents


class MoneyTest(unittest.TestCase):
    def test_usd(self):
        self.assertEqual(fmt_money(123456, "USD"), "$1,234.56")

    def test_gbp_uk(self):
        self.assertEqual(fmt_money(31240, "GBP", "en_GB"), "£312.40")

    def test_eur_de(self):
        self.assertEqual(fmt_money(123456, "EUR", "de_DE"), "€1.234,56")

    def test_unknown_currency_falls_back_to_code(self):
        self.assertEqual(fmt_money(1200, "CHF"), "CHF 12.00")

    def test_negative(self):
        self.assertEqual(fmt_money(-500, "USD"), "-$5.00")

    def test_parse(self):
        self.assertEqual(parse_cents("12.3"), 1230)
        self.assertEqual(parse_cents("-5"), -500)


if __name__ == "__main__":
    unittest.main()

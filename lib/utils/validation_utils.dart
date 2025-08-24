class PurchaseValidation {
  static const double minimumTokenAmount = 0.01;
  static const double maximumTokenAmount = 1000000.0;
  static const double maximumPurchaseAmount = 200.0; // Maximum $200 per transaction

  static String? validateTokenAmount(
    String? value,
    double availableStock,
    double userWalletBalance,
    String currencySymbol,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please enter token amount';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Token amount must be greater than zero';
    }

    if (amount < minimumTokenAmount) {
      return 'Minimum purchase amount is ${minimumTokenAmount.toStringAsFixed(2)} tokens';
    }

    if (amount > maximumTokenAmount) {
      return 'Maximum purchase amount is ${maximumTokenAmount.toStringAsFixed(0)} tokens';
    }

    if (amount > availableStock) {
      return 'Not enough tokens available. Available: ${availableStock.toStringAsFixed(2)}';
    }

    return null; // No validation error
  }

  static String? validateWalletBalance(
    double tokenAmount,
    double tokenPrice,
    double userWalletBalance,
    String currencySymbol,
  ) {
    final totalCost = tokenAmount * tokenPrice;

    if (totalCost > maximumPurchaseAmount) {
      return 'Maximum purchase limit is $currencySymbol${maximumPurchaseAmount.toStringAsFixed(2)} per transaction. Current: $currencySymbol${totalCost.toStringAsFixed(2)}';
    }

    if (totalCost > userWalletBalance) {
      return 'Insufficient wallet balance. Required: $currencySymbol${totalCost.toStringAsFixed(2)}, Available: $currencySymbol${userWalletBalance.toStringAsFixed(2)}';
    }

    return null; // No validation error
  }

  static bool canPurchase(
    String tokenAmountText,
    double availableStock,
    double userWalletBalance,
    double tokenPrice,
    String currencySymbol,
  ) {
    final tokenValidation = validateTokenAmount(tokenAmountText, availableStock, userWalletBalance, currencySymbol);
    if (tokenValidation != null) return false;

    final amount = double.tryParse(tokenAmountText) ?? 0.0;
    final walletValidation = validateWalletBalance(amount, tokenPrice, userWalletBalance, currencySymbol);
    if (walletValidation != null) return false;

    return true;
  }
}

class SellValidation {
  static const double minimumTokenAmount = 0.01;

  static String? validateSellAmount(
    String? value,
    double ownedTokens,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please enter token amount to sell';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Sell amount must be greater than zero';
    }

    if (amount < minimumTokenAmount) {
      return 'Minimum sell amount is ${minimumTokenAmount.toStringAsFixed(2)} tokens';
    }

    if (amount > ownedTokens) {
      return 'Not enough tokens owned. You have: ${ownedTokens.toStringAsFixed(2)} tokens';
    }

    return null; // No validation error
  }

  static bool canSell(String tokenAmountText, double ownedTokens) {
    final validation = validateSellAmount(tokenAmountText, ownedTokens);
    return validation == null;
  }
}

# 手动进场 - 开空
symbol = "BTC/USDC:USDC"
timeframe = '15m'
limit = 6
df = get_kline(exchange, symbol, timeframe, limit)

# 进场价
enter_price = df.iloc[0]['high']
print(f"进场价: {enter_price}")

amount = 0.002

# 1. 开仓单
exchange.create_limit_sell_order(symbol, amount, enter_price, {
    'positionSide': 'SHORT',
    'timeInForce': 'PO'
})

# 2. 止损单（价格更高，买入平仓）
sl_price = enter_price + 1000
exchange.create_limit_buy_order(symbol, amount, sl_price, {
    'positionSide': 'SHORT',
    'stopLossPrice': sl_price,
    'timeInForce': 'GTC'  # 止损用 GTC
})

# 3. 止盈单（价格更低，买入平仓）
tp_price = enter_price - 1000
exchange.create_limit_buy_order(symbol, amount, tp_price, {
    'positionSide': 'SHORT',
    'takeProfitPrice': tp_price,
    'timeInForce': 'GTC'  # 止盈用 GTC
})

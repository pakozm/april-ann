local AD   = autodiff
local op   = AD.op
local func = AD.func
local a,w,w2,seed  = AD.matrix('a w w2 seed')
local b,c = AD.matrix('b c')

local rnd = random(1234)
local M   = matrix.col_major

weights = {
  w  = M(3,4):uniformf(0,1,rnd),
  b  = M(3,1):uniformf(0,1,rnd),
  w2 = M(2,3):uniformf(0,1,rnd),
  c  = M(2,1):uniformf(0,1,rnd),
}

w:shape(table.unpack(weights.w:dim()))
b:shape(table.unpack(weights.b:dim()))
w2:shape(table.unpack(weights.w2:dim()))
c:shape(table.unpack(weights.c:dim()))

function logistic(s)
  return 1/(1 + op.exp(-s))
end

f = logistic(w2 * logistic( w * a + b ) + c)

AD.dot_graph(f, "wop.dot")

df_dw_tbl = table.pack( f, AD.diff(f, {w, b, w2, c}) )

AD.dot_graph(df_dw_tbl[2], "wop2.dot")

df_dw = AD.func(df_dw_tbl, {a}, weights )

result = table.pack(  df_dw( M(4,1):uniformf(0,1,rnd) ) )
iterator(ipairs(result)):select(2):apply(print)

---------------------------------------------------------------------

-- SYMBOLIC DECLARATION
AD.clear()
-- inputs
local x,s,h = AD.matrix('x s h')
-- target
local target = AD.matrix('target')
-- weights
local wx,ws1,wh1,ws2,wh2,b = AD.matrix('wx ws1 wh1 ws2 wh2 b')
-- gradient seed
local seed = AD.matrix('seed')
-- equation
f = wx*x + ws1*s + wh1*h + (ws2*s + wh2*h) * op.get(x,1,1) + b

-- loss
L = autodiff.op.sum( (f - target)^2 )

-- INSTANTIATION
local rnd = random(1234)
local M   = matrix.col_major

weights = {
  wx  = M(12,3):uniformf(-0.1, 0.1, rnd),
  ws1 = M(12,4):uniformf(-0.1, 0.1, rnd),
  wh1 = M(12,24):uniformf(-0.1, 0.1, rnd),
  ws2 = M(12,4):uniformf(-0.1, 0.1, rnd),
  wh2 = M(12,24):uniformf(-0.1, 0.1, rnd),
  b   = M(12,1):uniformf(-0.1, 0.1, rnd)
}

AD.dot_graph(f, "wop.dot")

df_dw_tbl = table.pack( f, AD.diff(f, {wx, ws1, wh1, ws2, wh2, b}, seed) )

AD.dot_graph(df_dw_tbl[5], "wop2.dot")

df_dw     = AD.func(df_dw_tbl, {x,s,h,seed}, weights )

result = table.pack(  df_dw( M(3,1):uniformf(0,1,rnd),
			     M(4,1):uniformf(0,1,rnd),
			     M(24,1):zeros():set(10,1,1),
			     M(12,1):uniformf(0,1,rnd) ) )
iterator(ipairs(result)):select(2):apply(print)

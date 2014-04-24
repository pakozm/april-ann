local check = utest.check
--
a = matrix.fromString[[
1 3
ascii col_major
1 2 3
]]

b = matrix.fromString[[
3 1
ascii col_major
1
4
7
]]

c = a*b
check.eq(c:get(1,1), 1*1+2*4+3*7)

check.eq(b*a, matrix.col_major(3,3,{
                                 1,  2,  3,
                                 4,  8, 12,
                                 7, 14, 21,
                                   }))

d = matrix.fromString[[
3 3
ascii
1 2 3
4 5 6
7 8 9
]]

check.eq(d:clone("col_major"), matrix.col_major(3,3,{
                                                  1, 2, 3,
                                                  4, 5, 6,
                                                  7, 8, 9,
                                                    }))
check(d:transpose(), matrix(3,3,{
                              1, 4, 7,
                              2, 5, 8,
                              3, 6, 9,
                                }))
e = d * d 
check(e, matrix(3,3,{
                  30,   36,  42,
                  66,   81,  96,
                  102, 126, 150,
                    }))

d = d:clone("col_major")
e = d * d
check(e, matrix.col_major(3,3,{
                            30,   36,  42,
                            66,   81,  96,
                            102, 126, 150,
                              }))

h = d:slice({2,2},{2,2})
check(h, matrix.col_major(2,2,{
                            5, 6,
                            8, 9,
                              }))

e = h * h
check(e, matrix.col_major(2,2,{
                            73,  84,
                            112, 129,
                              }))

l = matrix.col_major(2,2):fill(4) + h
check(l, matrix.col_major(2,2,{
                            9, 10,
                            12, 13,
                              }))

g = matrix(3,2,{1,2,
		3,4,
		5,6})
check(g:transpose():clone("col_major"), matrix.col_major(2,3,{
                                                           1, 3, 5,
                                                           2, 4, 6,
                                                             }))
check(g:transpose():clone("col_major"):clone("row_major"), matrix(2,3,{
                                                                    1, 3, 5,
                                                                    2, 4, 6,
                                                                      }))
check(g:transpose(), matrix(2,3,{
                              1, 3, 5,
                              2, 4, 6,
                                }))
j = g:transpose() * g
check(j, matrix(2,2,{
                  35, 44,
                  44, 56,
                    }))

j = matrix(2,2):gemm{
  trans_A=true, trans_B=false,
  alpha=1.0, A=g, B=g,
  beta=0.0
}
check(j, matrix(2,2,{
                  35, 44,
                  44, 56,
                    }))

j = matrix.col_major(2,2):gemm{
  trans_A=true, trans_B=false,
  alpha=1.0, A=g:clone("col_major"), B=g:clone("col_major"),
  beta=0.0
}
check(j, matrix.col_major(2,2,{
                            35, 44,
                            44, 56,
                              }))

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------

local m = matrix.col_major(4,5,{1,0,0,0,2,
				0,0,3,0,0,
				0,0,0,0,0,
				0,4,0,0,0})
local U,S,V = m:svd()
check(U, matrix.col_major(4,4,
                          {
                            0,0,1, 0,
                            0,1,0, 0,
                            0,0,0,-1,
                            1,0,0, 0,
                          }))
check(S:to_dense(), matrix.col_major(4,{4,3,2.23607,0}):diagonalize())
check(V, matrix.col_major(5,5,
                          {
                            0,1,0,0,0,
                            0,0,1,0,0,
                            0.447214,0,0,0,0.894427,
                            0,0,0,1,0,
                              -0.894427,0,0,0,0.447214,
                          }))

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------

local m = matrix(20,20):uniformf()
local subm = m:slice({5,4},{6,9})
check.eq(subm, m("5:10","4:12"))
check.eq(subm, m({5,10},{4,12}))
local subm = m:slice({1,4},{6,m:dim(2)-3})
check.eq(subm, m(":6","4:"))

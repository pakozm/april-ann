learning_rate  = 0.4
momentum       = 0.1
weight_decay   = 1e-05
semilla        = 1234
aleat          = random(semilla)
bunch_size     = tonumber(arg[1]) or 64
delta          = 1e-05

initial_result = {
  0.18666581809521,
  0.16942968964577,
  0.17109067738056,
  0.14423334598541
}

final_result = {
  0.0095419613644481,
  0.99107891321182,
  0.99107879400253,
  0.010305323638022
}

m = matrix.fromString[[
    19
    ascii
       1.0 0.1 0.2
      -1.0 0.3 0.4
      -0.5 -1.2 1.0
      -2.0 4.0 -4.0
       0.1 1.1 -1.5
      -1.0 2.0 2.0 -1.0
]]

bias0_m = matrix.fromString[[
    2
    ascii
      1.0
     -1.0
]]

bias1_m = matrix.fromString[[
    3
    ascii
      -0.5
      -2.0
       0.1
]]
bias2_m = matrix.fromString[[
    1
    ascii
      -1.0
]]
w0_m = matrix.fromString[[
    4
    ascii
      0.1 0.2
      0.3 0.4
]]
w1t_m = matrix.fromString[[
    6
    ascii
      -1.2 4.0 1.1
       1.0 -4.0 -1.5
]]
w2_m = matrix.fromString[[
    3
    ascii
      2.0 2.0 -1.0
]]

function show_weights(lared)
  lared:show_weights()
  print()
  local outds = dataset.matrix(matrix(4))
  lared:use_dataset{ input_dataset = ds_input, output_dataset = outds }
  for i = 1,ds_input:numPatterns() do
    value = lared:calculate(ds_input:getPattern(i))[1]
    printf("%s\t %s\t %s\n",
	   table.concat(ds_input:getPattern(i),","),
	   value,
	   outds:getPattern(i)[1])
  end
  print()
end

function check_result(lared, result)
  local outds = dataset.matrix(matrix(4))
  lared:use_dataset{ input_dataset = ds_input, output_dataset = outds }
  for i = 1,ds_input:numPatterns() do
    value = lared:calculate(ds_input:getPattern(i))[1]
    if math.abs(value - result[i]) > delta then
      error("Incorrect result using bunch_size=1!!!")
    end
    if math.abs(outds:getPattern(i)[1] - result[i]) > delta then
      error("Incorrect result using bunch_size=" .. bunch_size .."!!!")
    end
  end
end

-----------------------------------------------------------

lared = ann.mlp{ bunch_size = bunch_size }
-- neuron layers
i  = ann.units.real_cod{ size = 2, ann = lared, type = "inputs" }
h0 = ann.units.real_cod{ size = 2, ann = lared, type = "hidden" }
h1 = ann.units.real_cod{ size = 3, ann = lared, type = "hidden" }
o  = ann.units.real_cod{ size = 1, ann = lared, type = "outputs" }

-- connection layers
b0 = ann.connections.bias{ size = h0:num_neurons(), ann = lared }
c0 = ann.connections.all_all{ input_size = i:num_neurons(),
			      output_size = h0:num_neurons(), ann = lared }
b1 = ann.connections.bias{ size = h1:num_neurons(), ann = lared }
c1 = ann.connections.all_all{ input_size = h1:num_neurons(),
			      output_size = h0:num_neurons(), ann = lared }
b2 = ann.connections.bias{ size = o:num_neurons(), ann = lared }
c2 = ann.connections.all_all{ input_size = h1:num_neurons(),
			      output_size = o:num_neurons(), ann = lared }

-- first layer actions
ann.actions.forward_bias{ ann = lared, output = h0, connections = b0 }
ann.actions.dot_product{  ann = lared, input = i, output = h0, connections = c0 }
ann.actions.activations{  ann = lared, actfunc = ann.activations.tanh(),
			  output = h0 }
-- second layer actions
ann.actions.forward_bias{ ann = lared, output = h1, connections = b1 }
ann.actions.dot_product{  ann = lared, input = h0, output = h1, connections = c1,
			  transpose = true }
ann.actions.activations{  ann = lared, actfunc = ann.activations.tanh(),
			  output = h1 }

-- third layer actions
ann.actions.forward_bias{ ann = lared, output = o, connections = b2 }
ann.actions.dot_product{  ann = lared, input = h1, output = o, connections = c2 }
ann.actions.activations{  ann = lared, actfunc = ann.activations.logistic(),
			  output = o }

-- load connecctions
b0:load{ w = bias0_m }
b1:load{ w = bias1_m }
b2:load{ w = bias2_m }
c0:load{ w = w0_m }
c1:load{ w = w1t_m }
c2:load{ w = w2_m }

lared:set_option("learning_rate", learning_rate)
lared:set_option("momentum",      momentum)
lared:set_option("weight_decay",  weight_decay)

lared2=ann.mlp.all_all.generate{
  topology   = "2 inputs 2 tanh 3 tanh 1 logistic",
  w          = m,
  oldw       = m,
  bunch_size = bunch_size,
			       }
lared2:set_option("learning_rate", learning_rate)
lared2:set_option("momentum",      momentum)
lared2:set_option("weight_decay",  weight_decay)

m_xor = matrix.fromString[[
    4 3
    ascii
    0 0 0
    0 1 1
    1 0 1
    1 1 0
]]

ds_input  = dataset.matrix(m_xor,{patternSize={1,2}})
ds_output = dataset.matrix(m_xor,{offset={0,2},patternSize={1,1}})

--------
-- GO --
--------

check_result(lared,  initial_result)
check_result(lared2, initial_result)

data = {
  input_dataset  = ds_input,
  output_dataset = ds_output,
  shuffle        = random(1234)
}
data2 = {
  input_dataset  = ds_input,
  output_dataset = ds_output,
  shuffle        = random(1234)
}

for i=1,30000 do
  lared:train_dataset(data)
  lared2:train_dataset(data2)
end

check_result(lared,  final_result)
check_result(lared2, final_result)

print("TEST PASSED!")

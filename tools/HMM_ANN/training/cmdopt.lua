dropout_table = {
  layers = { }
}

cmdOptTest = cmdOpt{
  program_name = string.basename(arg[0]),
  argument_description = "",
  main_description = "HMM/ANN training with April-ANN toolkit",
  {
    index_name="defopt",
    description="Load configuration file (a lua tabla)",
    short="f",
    argument="yes",
    filter=dofile,
  },
  {
    index_name="bunch_size",
    description="Bunch size (mini-batch size)",
    long="bunch-size",
    argument="yes",
    mode="always",
    filter=tonumber,
    default_value=32,
  },
  {
    index_name="train_m",
    description="MFCC file for training set",
    long="train-m",
    argument="yes",
    mode="always",
  },
  {
    index_name="train_f",
    description="FON file for training set",
    long="train-f",
    argument="yes",
    mode="always",
  },
  {
    index_name="train_s",
    description="Initial segmentation file for training set",
    long="train-s",
    argument="yes",
  },
  {
    index_name="train_phdict",
    description="Phonetical dictionary for training",
    long="train-phdict",
    argument="yes",
  },
  {
    index_name="val_m",
    description="MFCC file for validation set",
    long="val-m",
    argument="yes",
    mode="always",
  },
  {
    index_name="val_f",
    description="FON file for validation set",
    long="val-f",
    argument="yes",
    mode="always",
  },
  {
    index_name="val_s",
    description="Initial segmentation file for validation set",
    long="val-s",
    argument="yes",
  },
  {
    index_name="val_phdict",
    description="Phonetical dictionary for validation",
    long="val-phdict",
    argument="yes",
  },
  {
    index_name="begin_sil",
    description="Initial silence",
    long="begin-sil",
    argument="yes",
  },
  {
    index_name="end_sil",
    description="Final silence",
    long="end-sil",
    argument="yes",
  },
  {
    index_name="count_values",
    description="Blank separated list of Viterbi count values, for use with multiple corpora",
    long="count-values",
    filter=function(s)
      return table.imap(string.tokenize(s, " ,\t\n\r"),tonumber)
    end,
    argument="yes",
    mode="always",
    default_value="",
  },
  {
    index_name="num_states",
    description="Number of states per each HMM",
    long="num-states",
    filter=tonumber,
    mode="always",
    argument="yes",
    default_value=false,
  },
  {
    index_name="h1",
    description="First hidden layer size",
    long="h1",
    argument="yes",
    mode="always",
    filter=tonumber,
  },
  {
    index_name="h2",
    description="Second hidden layer size",
    long="h2",
    argument="yes",
    mode="always",
    filter=tonumber,
  },
  {
    index_name="n",
    description="Number of parameters per each frame",
    short="n",
    argument="yes",
    mode="always",
    filter=tonumber,
  },
  {
    index_name="train_r",
    description="Replacement for training (0 for disable)",
    long="train-r",
    argument="yes",
    mode="always",
    default_value=300000,
    filter=tonumber,
  },
  {
    index_name="val_r",
    description="Replacement for validation (0 for disable)",
    long="val-r",
    argument="yes",
    mode="always",
    default_value=0,
    filter=tonumber,
  },
  { index_name="tiedfile",
    description = "HTK unit's tied list",
    long = "tiedfile",
    argument = "yes",
    mode="always",
  },
  {
    index_name  = "context",
    description = "Size of ann context",
    long        = "context",
    argument    = "yes",
    mode="always",
    default_value=4,
    filter=tonumber,
  },
  {
    index_name  = "feats_format",
    description = "Format of features mat or mfc or png (mat, png or mfc)",
    long        = "feats-format",
    argument    = "yes",
    mode="always",
    default_value="mat",
  },
  {
    index_name  = "feats_norm",
    description = "Table with means and devs for features",
    long        = "feats-norm",
    argument    = "yes",
    filter      = dofile,
  },
  {
    index_name  = "step",
    description = "Dataset step",
    long        = "step",
    argument    = "yes",
    mode="always",
    default_value=1,
    filter=tonumber,
  },
  {
    index_name  = "mean",
    description = "Mean of gaussian perturbation",
    long        = "mean",
    argument    = "yes",
    mode="always",
    default_value=0,
    filter=tonumber,
  },
  {
    index_name  = "var",
    description = "Variance of gaussian perturbation (0 for disable)",
    long        = "var",
    argument    = "yes",
    mode="always",
    default_value=0.015,
    filter=tonumber,
  },
  {
    index_name  = "salt",
    description = "Salt noise percentage",
    long        = "salt",
    argument    = "yes",
    mode="always",
    default_value=0,
    filter=tonumber,
  },
  {
    index_name  = "seedp",
    description = "Perturbation seed",
    long        = "seedp",
    argument    = "yes",
    mode="always",
    default_value=86544,
    filter=tonumber,
  },
  {
    index_name = "firstlr",
    description = "First learning rate",
    long ="firstlr",
    argument="yes",
    mode="always",
    default_value=0.005,
    filter=tonumber,
  },
  {
    index_name = "epochs_firstlr",
    description = "Num epochs for first learning rate",
    long ="epochs-firstlr",
    argument="yes",
    mode="always",
    default_value=100,
    filter=tonumber,
  },
  {
    index_name = "lr",
    description = "Learning rate",
    long ="lr",
    argument="yes",
    mode="always",
    default_value=0.001,
    filter=tonumber,
  },
  {
    index_name = "mt",
    description = "Momentum",
    long ="mt",
    argument="yes",
    mode="always",
    default_value=0.005,
    filter=tonumber,
  },
  {
    index_name = "wd",
    description = "Weight decay",
    long ="wd",
    argument="yes",
    mode="always",
    default_value=1e-06,
    filter=tonumber,
  },
  {
    index_name = "mp",
    description = "Max normalization penalty, a negative value to disable it",
    long ="mp",
    argument="yes",
    mode="always",
    default_value=-1,
    filter=tonumber,
  },
  {
    index_name = "dropout",
    description = "Dropout: layer_name|||value",
    long ="dropout",
    argument="yes",
    mode="always",
    default_value="",
    action=function(name_and_value)
      local name,value = name_and_value:match("^(.*)|||(.*)$")
      table.insert(dropout_table, { name=name, value=value })
    end,
  },
  {
    index_name = "dropout_seed",
    description = "Dropout seed",
    long ="dropout-seed",
    argument="yes",
    mode="always",
    default_value=82975,
    filter=tonumber,
  },
  {
    index_name="rndw",
    description="Size of the random inf/sup for MLP",
    long="rndw",
    argument="yes",
    mode="always",
    default_value=0.1,
    filter=tonumber,
  },
  {
    index_name = "seed1",
    description = "Seed 1",
    long ="seed1",
    argument="yes",
    mode="always",
    default_value=1234,
    filter=tonumber,
  },
  {
    index_name = "seed2",
    description = "Seed 2",
    long ="seed2",
    argument="yes",
    mode="always",
    default_value=4567,
    filter=tonumber,
  },
  {
    index_name = "seed3",
    description = "Seed 3",
    long ="seed3",
    argument="yes",
    mode="always",
    default_value=9876,
    filter=tonumber,
  },
  {
    index_name = "epochs_wo_val",
    description = "Epochs without validation",
    long ="epochs-wo-val",
    argument="yes",
    mode="always",
    default_value=4,
    filter=tonumber,
  },
  {
    index_name = "epochs_wo_imp",
    description = "Epochs without improvement",
    long ="epochs-wo-imp",
    argument="yes",
    mode="always",
    default_value=20,
    filter=tonumber,
  },
  {
    index_name = "epochs_wo_exp",
    description = "Epochs without expectation step",
    long ="epochs-wo-exp",
    argument="yes",
    mode="always",
    default_value=5,
    filter=tonumber,
  },
  {
    index_name = "epochs_max",
    description = "Number of epochs for maximization step",
    long ="epochs-max",
    argument="yes",
    mode="always",
    default_value=100,
    filter=tonumber,
  },
  {
    index_name = "epochs_first_max",
    description = "Number of epochs for first maximization step",
    long ="epochs-first-max",
    argument="yes",
    mode="always",
    default_value=500,
    filter=tonumber,
  },
  {
    index_name = "em_it",
    description = "Number of EM iterations",
    long ="em-it",
    argument="yes",
    mode="always",
    default_value=100,
    filter=tonumber,
  },
  {
    index_name = "dropped_em_iterations",
    description = "The number of EM iterations where the ANN is reinitialized from scratch",
    long ="dropped-em-iterations",
    argument="yes",
    mode="always",
    default_value=0,
    filter=tonumber,
  },
  {
    index_name="pretrained_mlp",
    description="Initial pretrained MLP",
    long="pretrained-mlp",
    argument="yes",
  },
  {
    index_name="initial_mlp",
    description="Initial MLP for continue an stopped training",
    long="initial-mlp",
    argument="yes",
  },
  {
    index_name="initial_hmm",
    description="Initial HMM for continue an stopped training, or to use as a first HMM description",
    long="initial-hmm",
    argument="yes",
  },
  {
    index_name="initial_em_epoch",
    description="Initial EM epoch for continue an stopped training",
    long="initial-em-epoch",
    argument="yes",
    filter=tonumber,
  },
  {
    index_name="transcription_filter",
    description="Filter the transcriptions to generate phonetic sequences",
    long="transcription-filter",
    argument="yes",
    filter=dofile,
  },
  {
    index_name="silences",
    description="HMM models for silences (a blank separated list)",
    long="silences",
    argument="yes",
    filter=string.tokenize,
    mode="always",
    default_value="",
  },
  {
    description = "shows this help message",
    short = "h",
    long = "help",
    argument = "no",
    action = function (argument) 
	       print(cmdOptTest:generate_help()) 
	       os.exit(1)
	     end    
  }
}

local optargs = cmdOptTest:parse_without_check()
if type(optargs) == "string" then error(optargs) end

local initial_values
if optargs.defopt then
  initial_values = optargs.defopt
  optargs.defopt=nil
end
optargs = cmdOptTest:check_args(optargs, initial_values)

return optargs,dropout_table

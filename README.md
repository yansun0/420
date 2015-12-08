# 420

## Gender Classification/Neural Networks
######Found in: code/neural_networks
- Deploy.prototxt is the model to feed in the images
- snapshot_iter_240.caffemodel are the weights
- mean.binaryproto is the mean image from the training
- solver.prototxt and train_val.prototxt are there if you would like to run it on your own training data

## Face Tracking
######Found in: code/jimmy_code
- compute_area.m, compute_center.m, compute_similiarity.m were created such that they can be called without cluttering a file
- modify track_objects.m to have the dets in mat files which are found in train_data. The paths may need to be modified to work

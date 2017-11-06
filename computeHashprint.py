import numpy as np
import tensorflow as tf
import scipy.io as sio
import time
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import sys
import os
import hdf5storage

# global config
nbins = 121
nframes = 20
nfilters = 64
hop = 5
deltaDelay = 16

def preprocessQspec(Q, downsample=3):
	'''
		preprocess the spec by taking log and downsampling by smoothing
	'''
	nPitches = Q.shape[0]
	nChunks = int(np.floor(Q.shape[1] / downsample))
	A = abs(Q[:, : nChunks * downsample])
	A = np.mean(A.reshape(-1, downsample), axis=1).reshape(nPitches, -1)
	A = A.reshape(nPitches, -1)

	return np.log(1 + 1000000 * A)

def pitchshift(M, shiftBins):
	'''
		pitchshift equivalent of Prof Tsai's code in matlab

		return: a pitchshifted matrix
	'''
	shifted = np.roll(M, shiftBins, axis=0)
	if shiftBins > 0:
		shifted[:shiftBins, :] = 0.
	else:
		shifted[shiftBins:, :] = 0.
	return shifted


# network setup
def get_hp(X, l1filters, l2filters):
	'''
		get representation using a two-layer CNN

		return: an np array representation of a given CQT matrix X
	'''
	x = tf.placeholder(tf.float32, [nbins, None])
	input_layer = tf.reshape(x, [1, nbins, -1, 1])
	# apply PCA filters
	conv1 = tf.layers.conv2d(
		inputs=input_layer,
		filters=l1filters.shape[2],
		kernel_size=[l1filters.shape[0], l1filters.shape[1]],
		strides=(1, hop),
		use_bias=False,
		kernel_initializer=tf.constant_initializer(l1filters))

	# volume invariant
	conv2 = tf.layers.conv2d(
		inputs=tf.reshape(conv1, [1, l1filters.shape[2], -1, 1]),
		filters=1,
		kernel_size=[l2filters.shape[0], l2filters.shape[1]],
		use_bias=False,
		kernel_initializer=tf.constant_initializer(l2filters))

	
	sess = tf.Session()
	sess.run(tf.global_variables_initializer())

	rep = np.reshape(conv2.eval(feed_dict={x: X}, session=sess), (nfilters, -1))
	return rep



if __name__ == '__main__':
	delay_filter = np.zeros((1, deltaDelay + 1), dtype='f')
	delay_filter[0, 0] = 1
	delay_filter[0, -1] = -1
	artist = 'taylorswift'
	outdir = './' + artist + '_out/'

	# load PCA filters
	filter_file = 'rep1_64.mat'
	PCA_filters = sio.loadmat(outdir + filter_file)['eigvecs']
	PCA_filters = PCA_filters.reshape(nbins, nframes, nfilters).astype('f')

	def process_refs(ref_list, max_pitch_shift=4):
		ext = '.mat'
		f = open(ref_list, 'r')
		DB = {}
		index = 1
		for line in f:
			# get CQT matrix file name
			base = os.path.basename(line)
			filename, _ = os.path.splitext(base)
			matpath = outdir + filename + ext
			print("-- Generating representation for {t:s}".format(t=filename))
			# read CQT matrix
			Q = sio.loadmat(matpath)
			X = preprocessQspec(Q['Q']['c'][0][0])
			# generate representation fpr unshifted version
			origfpseq = get_hp(X, PCA_filters, delay_filter)
			# generate representations for pitch-shifted versions
			fpseqs = np.zeros((origfpseq.shape[0], origfpseq.shape[1], 2 * max_pitch_shift + 1))
			fpseqs[:, :, 0] = origfpseq
			for i in range(1, max_pitch_shift + 1):
				shiftQ = pitchshift(X, i)
				fpseqs[:, :, i] = get_hp(shiftQ, PCA_filters, delay_filter)
			for i in range(1, max_pitch_shift + 1):
				shiftQ = pitchshift(X, -i)
				fpseqs[:, :, i + max_pitch_shift] = get_hp(shiftQ, PCA_filters, delay_filter)
			DB[unicode("ref" + str(index))] = (fpseqs > 0)
			index += 1
		return DB

	def process_queries(query_list):
		ext = '.mat'
		f = open(query_list, 'r')
		DB = {}
		index = 1
		for line in f:
			# get CQT matrix file name
			base = os.path.basename(line)
			filename, _ = os.path.splitext(base)
			matpath = outdir + filename + ext
			print("-- Generating representation for {t:s}".format(t=filename))
			# read CQT matrix
			Q = sio.loadmat(matpath)
			X = preprocessQspec(Q['Q']['c'][0][0])
			# generate representation fpr unshifted version
			fpseq = get_hp(X, PCA_filters, delay_filter)
			DB[unicode("query" + str(index))] = (fpseq > 0)
			index += 1
		return DB

	# process ref files
	ref_list = './audio/taylorswift_ref.list'
	ref_db_path = outdir + 'ref_db.mat'
	ref_db = process_refs(ref_list)
	ref_db_data = {u"DB": ref_db, u"hopsize": hop}
	hdf5storage.write(ref_db_data, '.', ref_db_path, matlab_compatible=True)
	print("Reference files database saved to {}".format(ref_db_path))

	# # process query files
	# query_list = './audio/taylorswift_query.list'
	# query_db_path = outdir + 'query_db.mat'
	# query_db = process_queries(query_list)
	# query_db_data = {u"DB": query_db}
	# hdf5storage.write(query_db_data, '.', query_db_path, matlab_compatible=True)
	# print("Query files database saved to {}".format(query_db_path))

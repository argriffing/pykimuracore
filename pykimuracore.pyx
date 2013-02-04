"""
Fast functions for Kimura integrals.

This is related to population genetics.
For compilation instructions see
http://docs.cython.org/src/reference/compilation.html
For example:
$ cython -a kimengine.pyx
$ gcc -shared -pthread -fPIC -fwrapv -O2 -Wall -fno-strict-aliasing \
      -I/usr/include/python2.7 -o kimengine.so kimengine.c
"""

import numpy as np
cimport numpy as np
cimport cython
from libc.math cimport log, exp

np.import_array()

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def kimura_integrand(double x, double c, double d):
    cdef double n2cx = -2.*c*x
    cdef double retvalue =  exp(n2cx*d*(1.-x) + n2cx)
    return retvalue

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def denom_poly(double c, double d):
    """
    This is a polynomial approximation for small c and small d.
    But the smallness of c is more important.
    """
    cdef double accum = 0.
    cdef int k = 0
    #
    k = 0
    cdef double a_0 = 1.
    cdef double b_0 = (1./1.) * 1.
    accum += a_0 * b_0
    #
    k = 1
    cdef double a_1 = -a_0 * (2.*c) / k
    cdef double b_1 = (1./6.) * (3. + d)
    accum += a_1 * b_1
    #
    k = 2
    cdef double a_2 = -a_1 * (2.*c) / k
    cdef double b_2 = (1./30.) * (10. + d*(5. + d))
    accum += a_2 * b_2
    #
    k = 3
    cdef double a_3 = -a_2 * (2.*c) / k
    cdef double b_3 = (1./140.) * (35. + d*(21. + d*(7. + d)))
    accum += a_3 * b_3
    #
    k = 4
    cdef double a_4 = -a_3 * (2.*c) / k
    cdef double b_4 = (1./630.) * (126. + d*(84. + d*(36. + d*(9. + d))))
    accum += a_4 * b_4
    #
    k = 5
    cdef double a_5 = -a_4 * (2.*c) / k
    cdef double b_5 = (1./2772.) * (
            462. + d*(330. + d*(165. + d*(55. + d*(11. + d)))))
    accum += a_5 * b_5
    #
    k = 6
    cdef double a_6 = -a_5 * (2.*c) / k
    cdef double b_6 = (1./12012.) * (
            1716. + d*(1287. + d*(715. + d*(286. + d*(78. + d*(13. + d))))))
    accum += a_6 * b_6
    #
    return accum


@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
cdef double _kimura_integral_scalar(double c, double d) nogil:
    # This uses fixed-order (non-adaptive) Gaussian quadrature.
    # Note that because of symmetry
    # it would be possible to use only half as many hardcoded constants.

    cdef double *quad_points = [
            1.40330235114061175e-04,   7.39244005122874359e-04,
            1.81613360452764772e-03,   3.37020690606582018e-03,
            5.40000456248135308e-03,   7.90358918488964779e-03,
            1.08785648567778503e-02,   1.43220827209142865e-02,
            1.82308445834328259e-02,   2.26011063644048216e-02,
            2.74286817976757136e-02,   3.27089464905262473e-02,
            3.84368423771943579e-02,   4.46068825763037413e-02,
            5.12131566535618532e-02,   5.82493362873209297e-02,
            6.57086813329343933e-02,   7.35840462807441087e-02,
            8.18678871018548859e-02,   9.05522684753715112e-02,
            9.96288713902561684e-02,   1.09089001114628437e-01,
            1.18923595524876635e-01,   1.29123233786658076e-01,
            1.39678145379490914e-01,   1.50578219456277973e-01,
            1.61813014528822741e-01,   1.73371768470077514e-01,
            1.85243408823509703e-01,   1.97416563409758439e-01,
            2.09879571220363048e-01,   2.22620493588213175e-01,
            2.35627125623930622e-01,   2.48887007907288793e-01,
            2.62387438422460595e-01,   2.76115484725631299e-01,
            2.90057996333365653e-01,   3.04201617319828199e-01,
            3.18532799110809006e-01,   3.33037813462284005e-01,
            3.47702765611093645e-01,   3.62513607585129960e-01,
            3.77456151660290118e-01,   3.92516083951295225e-01,
            4.07678978123371505e-01,   4.22930309211641653e-01,
            4.38255467535005050e-01,   4.53639772691158683e-01,
            4.69068487619375807e-01,   4.84526832717550815e-01,
            5.00000000000000000e-01,   5.15473167282449074e-01,
            5.30931512380624082e-01,   5.46360227308841373e-01,
            5.61744532464995339e-01,   5.77069690788358125e-01,
            5.92321021876628495e-01,   6.07483916048704664e-01,
            6.22543848339709660e-01,   6.37486392414869707e-01,
            6.52297234388906300e-01,   6.66962186537716217e-01,
            6.81467200889190661e-01,   6.95798382680170691e-01,
            7.09942003666633736e-01,   7.23884515274368479e-01,
            7.37612561577539294e-01,   7.51112992092709653e-01,
            7.64372874376070044e-01,   7.77379506411785881e-01,
            7.90120428779638173e-01,   8.02583436590241450e-01,
            8.14756591176491130e-01,   8.26628231529922930e-01,
            8.38186985471176427e-01,   8.49421780543724081e-01,
            8.60321854620508697e-01,   8.70876766213341424e-01,
            8.81076404475126029e-01,   8.90910998885370842e-01,
            9.00371128609743110e-01,   9.09447731524629210e-01,
            9.18132112898144337e-01,   9.26415953719254781e-01,
            9.34291318667066273e-01,   9.41750663712680347e-01,
            9.48786843346439812e-01,   9.55393117423696703e-01,
            9.61563157622807085e-01,   9.67291053509474530e-01,
            9.72571318202324786e-01,   9.77398893635599508e-01,
            9.81769155416567507e-01,   9.85677917279086047e-01,
            9.89121435143223926e-01,   9.92096410815112240e-01,
            9.94599995437517759e-01,   9.96629793093932848e-01,
            9.98183866395470409e-01,   9.99260755994877847e-01,
            9.99859669764885717e-01]

    cdef double *quad_weights = [
            3.60115853202061455e-04,   8.37946380247302182e-04,
            1.31568243659202478e-03,   1.79221969940361603e-03,
            2.26705250504413876e-03,   2.73971734189285346e-03,
            3.20975913508865854e-03,   3.67672683739475679e-03,
            4.14017281286131744e-03,   4.59965297046071708e-03,
            5.05472708975683496e-03,   5.50495920402918702e-03,
            5.94991800135962964e-03,   6.38917723004265355e-03,
            6.82231610311145441e-03,   7.24891969931846201e-03,
            7.66857935952323152e-03,   8.08089307747761158e-03,
            8.48546588454622726e-03,   8.88191022780702999e-03,
            9.26984634114584767e-03,   9.64890260895827703e-03,
            1.00187159220469363e-02,   1.03789320254231605e-02,
            1.07292058576161104e-02,   1.10692018811988872e-02,
            1.13985944042040606e-02,   1.17170678920823761e-02,
            1.20243172699692168e-02,   1.23200482149146175e-02,
            1.26039774378124188e-02,   1.28758329547765792e-02,
            1.31353543476735845e-02,   1.33822930135859743e-02,
            1.36164124029540222e-02,   1.38374882461650400e-02,
            1.40453087684001884e-02,   1.42396748924846217e-02,
            1.44204004295975293e-02,   1.45873122576251086e-02,
            1.47402504869966217e-02,   1.48790686138486374e-02,
            1.50036336603655580e-02,   1.51138263021610274e-02,
            1.52095409825821950e-02,   1.52906860138265262e-02,
            1.53571836647705615e-02,   1.54089702354320464e-02,
            1.54459961179887022e-02,   1.54682258442986869e-02,
            1.54756381198785480e-02,   1.54682258442989974e-02,
            1.54459961179887473e-02,   1.54089702354320429e-02,
            1.53571836647705857e-02,   1.52906860138264256e-02,
            1.52095409825822366e-02,   1.51138263021610986e-02,
            1.50036336603658130e-02,   1.48790686138488212e-02,
            1.47402504869966026e-02,   1.45873122576250219e-02,
            1.44204004295983446e-02,   1.42396748924840597e-02,
            1.40453087684004833e-02,   1.38374882461658518e-02,
            1.36164124029536076e-02,   1.33822930135853221e-02,
            1.31353543476733121e-02,   1.28758329547762930e-02,
            1.26039774378120424e-02,   1.23200482149146019e-02,
            1.20243172699695602e-02,   1.17170678920821090e-02,
            1.13985944042038143e-02,   1.10692018811996053e-02,
            1.07292058576148198e-02,   1.03789320254208985e-02,
            1.00187159220497032e-02,   9.64890260895755018e-03,
            9.26984634114546083e-03,   8.88191022780679754e-03,
            8.48546588454710850e-03,   8.08089307747635911e-03,
            7.66857935952244656e-03,   7.24891969932101466e-03,
            6.82231610310821482e-03,   6.38917723004631642e-03,
            5.94991800135640739e-03,   5.50495920402934748e-03,
            5.05472708975592162e-03,   4.59965297046031635e-03,
            4.14017281286194801e-03,   3.67672683739513799e-03,
            3.20975913509141675e-03,   2.73971734189255248e-03,
            2.26705250504531360e-03,   1.79221969940258777e-03,
            1.31568243658948319e-03,   8.37946380246250180e-04,
            3.60115853202378801e-04]

    cdef double u = 0.0
    cdef double x = 0.0
    cdef double w = 0.0
    cdef int i = 0
    for i in range(101):
        x = quad_points[i]
        w = quad_weights[i]
        u += w * exp(-2*c*d*x*(1.-x) - 2*c*x)
    return u

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.cdivision(True)
def kimura_integral_2d_masked_inplace(
        np.ndarray[np.float64_t, ndim=2] C,
        np.ndarray[np.float64_t, ndim=2] D,
        np.ndarray[np.int_t, ndim=2] M,
        np.ndarray[np.float64_t, ndim=2] out,
        ):
    """
    Give up on writing ufuncs and instead use ndarrays with explicit ndim.
    Use a separate integer array as the mask rather than trying to use
    the numpy masked array feature.
    All of the ndarray arguments should have the same shape.
    @param C: selection
    @param D: dominance
    @param M: mask
    @param out: write into this array
    """
    cdef int n = C.shape[0]
    cdef int k = C.shape[1]
    cdef int i = 0
    cdef int j = 0
    for i in range(n):
        for j in range(k):
            if M[i, j] != 0:
                out[i, j] = _kimura_integral_scalar(C[i, j], D[i, j])
    return out


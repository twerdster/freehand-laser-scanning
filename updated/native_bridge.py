"""ctypes access to the same Accelerate C core built into the simulator app."""
import ctypes as ct
import numpy as np

class Native:
    def __init__(self, path):
        self.lib = ct.CDLL(str(path))
        f = ct.POINTER(ct.c_float)
        d = ct.POINTER(ct.c_double)
        self.lib.laser_response.argtypes = [f, ct.c_int, ct.c_int, f]
        self.lib.laser_extract.argtypes = [f, ct.c_int, ct.c_int, ct.c_double, d]
        self.lib.laser_points.argtypes = [d, ct.c_int, d, d, d, d]
        self.lib.laser_calibration_points.argtypes = [d, ct.c_int, d, d, d, d]
        self.lib.laser_fit_plane.argtypes = [d, ct.c_int, d]
    @staticmethod
    def d(a):
        return np.ascontiguousarray(a, dtype=np.float64)
    @staticmethod
    def ptr(a):
        return a.ctypes.data_as(ct.POINTER(ct.c_double))
    def extract(self, image, threshold=8.):
        a = np.ascontiguousarray(image, dtype=np.float32)
        self.image_shape(a)
        out = np.zeros((a.shape[1], 2), dtype=np.float64)
        n = self.lib.laser_extract(a.ctypes.data_as(ct.POINTER(ct.c_float)), a.shape[1], a.shape[0], threshold, self.ptr(out))
        if n < 0:
            raise ValueError('Native extraction rejected input')
        return out[:n]
    def response(self, image):
        a = np.ascontiguousarray(image, dtype=np.float32)
        self.image_shape(a)
        out = np.zeros_like(a)
        status = self.lib.laser_response(a.ctypes.data_as(ct.POINTER(ct.c_float)), a.shape[1], a.shape[0], out.ctypes.data_as(ct.POINTER(ct.c_float)))
        if status:
            raise ValueError('Native filtering rejected input')
        return out
    @staticmethod
    def image_shape(a):
        if a.ndim != 2 or not all(11 <= size <= 2048 for size in a.shape):
            raise ValueError('Native image must be 2D with dimensions in [11,2048]')
    def points(self, uv, K, plane, T, calibration=False):
        arrays = [self.d(x) for x in (uv, K, plane, T)]
        uvs, k_array, plane_array, transform = arrays
        if (uvs.ndim != 2 or uvs.shape[1] != 2 or len(uvs) > 1000000
                or k_array.shape != (3, 3) or plane_array.shape != (4,) or transform.shape != (4, 4)):
            raise ValueError('Native geometry requires Nx2 pixels, 3x3 K, 4-plane and 4x4 pose')
        out = np.zeros((len(uv), 3))
        u, k, p, t = [self.ptr(a) for a in arrays]
        if calibration:
            n = self.lib.laser_calibration_points(u, len(uv), k, t, p, self.ptr(out))
        else:
            n = self.lib.laser_points(u, len(uv), k, p, t, self.ptr(out))
        if n < 0:
            raise ValueError('Native geometry rejected input')
        return out[:n]
    def fit(self, points):
        a, out = self.d(points), np.zeros(4)
        if a.ndim != 2 or a.shape[1] != 3 or not 4 <= len(a) <= 1000000:
            raise ValueError('Native calibration requires 4..1000000 points in Nx3 form')
        if self.lib.laser_fit_plane(self.ptr(a), len(a), self.ptr(out)):
            raise ValueError('Native plane fit rejected input')
        return out

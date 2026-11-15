#ifndef FREEHAND_LASER_CORE_H
#define FREEHAND_LASER_CORE_H
// New wrapper around recovered filtering/triangulation stages. See ../README.md.
int laser_response(const float *image, int width, int height, float *response);
int laser_extract(const float *image, int width, int height, double threshold, double *uv);
int laser_points(const double *uv, int count, const double *K, const double *plane,
                 const double *camera_to_world, double *xyz);
int laser_calibration_points(const double *uv, int count, const double *K,
                            const double *camera_to_world, const double *board, double *xyz);
int laser_fit_plane(const double *xyz, int count, double *plane);
#endif

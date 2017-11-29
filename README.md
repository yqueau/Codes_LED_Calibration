# Codes_LED_Calibration
Matlab codes for calibrating lighting (directional or (an)isotropic near point light source) using checkerboard

## Introduction

These Matlab codes implement the method for calibrating camera and lighting using checkerboard, as described in [1,2]. 

Features:
- 8 datasets, corresponding to the LEDs-lighting used in the near-light photometric stereo demos https://github.com/yqueau/near_ps 
- Possibility to calibrate either directional lighting (direction + colored intensities, for use for instance in the robust directional photometric stereo codes https://github.com/yqueau/robust_ps), isotropic near lighting (position + colored intensities of a near point light source) or anisotropic near lighting (position + orientation + colored intensities of a near point light source)

[1] "LED-based Photometric Stereo: Modeling, Calibration and Numerical Solution", Yvain Quéau et al., Journal of Mathematical Imaging and Vision, 2017 (dx.doi.org/10.1007/s10851-017-0761-1) 

[2] "Etalonnage de sources lumineuses de type LED", Bastien Durix et al., Proceedings of RFIA 2016. 

Please cite the above works if using the provided codes and/or datasets for your own research. 

Author: Yvain Quéau, Technical University Munich, yvain.queau@tum.de 

## Datasets

- The folders `Data1/` to `Data8/` contains images of a checkerboard. Each folder corresponds to one particular light source, and contains 25 poses of a black and white checkerboard. 

## Usage

See the `demo.m` file.

Required:
- folder with png images of the checkerboard under same lighting but different poses 
- size of the checkerboard squares in milimeters
- for near light source calibration: rough estimate of the position with respect to camera (axes: x to the right, y to the bottom, z to the scene)
- for anisotropic light source calibration: half-attenuation angle (provided by LEDs manufacturers)

Outputs:
- for directional lighting: direction (3x1, oriented from scene to source) and RGB intensities (3x1) 
- for near light: location wrt camera (3x1, in mm), and RGB intensities (3x1)
- for anisotropic near light: same + direction (3x1, from source to scene)
- camera's intrinsics

## Advices for data acquisition

If you want to try calibrating your own sources:
- be sure that the source to calibrate is the only source of light in the scene (no window, no neon, etc.). Our experiments are performed in a room without window, with walls painted diffuse black to avoid inter-reflections
- disable auto-exposure and auto white-balance of the camera
- set exposure and aperture appropriately to avoid saturation, yet have a broad enough range of values
- capture as many checkerboard poses as possible

## Important note for near-light position estimation 

For completeness, these codes can be used to refine the position of the LED. Note however that they are not intended to be considered as a "good" tool for accurately estimating the position. As discussed in [1,2], we rather advise to calibrate position using the standard specular balls-based procedure (or measure manually, if it is simple). We leave in these codes the option to refine position using checkerboard because we find it interesting, but use at your own risk.   

## Less important note on RGB images 

In [1,2], we describe the procedure for greylevel images, and then discuss simple extension to color using per-channel calibration. In the provided codes a somewhat more sound alternative based on nonlinear refinement is employed. Results are not so much different anyways, but we believe it is more justified from a mathematical perspective.  

## Dependencies

Requires Matlab's camera calibrator app, which is available in the computer vision toolbox.





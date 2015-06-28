//
//  SPLFloat.h
//  SPLCore
//
//  Created by Jonathan Hersh on 5/10/14.
//
//

@import Foundation;

#ifndef Pods_SPLFloat_h
#define Pods_SPLFloat_h

CG_INLINE CGFLOAT_TYPE SPLFloat_floor(CGFLOAT_TYPE cgfloat)
{
#if CGFLOAT_IS_DOUBLE
    return floor(cgfloat);
#else
    return floorf(cgfloat);
#endif
}

CG_INLINE CGFLOAT_TYPE SPLFloat_ceil(CGFLOAT_TYPE cgfloat)
{
#if CGFLOAT_IS_DOUBLE
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}

CG_INLINE CGFLOAT_TYPE SPLFloat_round(CGFLOAT_TYPE cgfloat)
{
#if CGFLOAT_IS_DOUBLE
    return round(cgfloat);
#else
    return roundf(cgfloat);
#endif
}

CG_INLINE CGFLOAT_TYPE SPLFloat_abs(CGFLOAT_TYPE cgfloat)
{
#if CGFLOAT_IS_DOUBLE
    return fabs(cgfloat);
#else
    return fabsf(cgfloat);
#endif
}

CG_INLINE CGFLOAT_TYPE SPLFloat_pow(CGFLOAT_TYPE cgfloat, CGFLOAT_TYPE exp)
{
#if CGFLOAT_IS_DOUBLE
    return pow(cgfloat, exp);
#else
    return powf(cgfloat, exp);
#endif
}

#endif

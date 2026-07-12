import QtQuick

NumberAnimation {
    enum Type {
        SpatialFast,
        SpatialDefault,
        SpatialSlow,
        EffectsFast,
        EffectsDefault,
        EffectsSlow,
        Emphasized,
        EmphasizedAccel,
        EmphasizedDecel,
        Standard,
        StandardAccel,
        StandardDecel,
        Progress,
        Bounce
    }

    property int type: Anim.SpatialDefault

    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        switch (type) {
            case Anim.SpatialFast:      return [0.42, 1.67, 0.21, 0.9,  1, 1]
            case Anim.SpatialDefault:   return [0.38, 1.21, 0.22, 1,    1, 1]
            case Anim.SpatialSlow:      return [0.39, 1.29, 0.35, 0.98, 1, 1]
            case Anim.EffectsFast:      return [0.31, 0.94, 0.34, 1,    1, 1]
            case Anim.EffectsDefault:   return [0.34, 0.8,  0.34, 1,    1, 1]
            case Anim.EffectsSlow:      return [0.34, 0.88, 0.34, 1,    1, 1]
            case Anim.Emphasized:       return [0.05, 0, 0.133, 0.06, 0.167, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
            case Anim.EmphasizedAccel:  return [0.3,  0, 0.8,   0.15, 1, 1]
            case Anim.EmphasizedDecel:  return [0.05, 0.7, 0.1,  1,    1, 1]
            case Anim.Standard:         return [0.2,  0,  0,     1,    1, 1]
            case Anim.StandardAccel:    return [0.3,  0,  1,     1,    1, 1]
            case Anim.StandardDecel:    return [0,    0,  0,     1,    1, 1]
            case Anim.Progress:         return [0.31, 0.94, 0.34, 1,    1, 1]
            case Anim.Bounce:           return [0.18, 1.52, 0.28, 0.98, 1, 1]
        }
    }

    duration: {
        switch (type) {
            case Anim.SpatialFast:      return 350
            case Anim.SpatialDefault:   return 500
            case Anim.SpatialSlow:      return 650
            case Anim.EffectsFast:      return 150
            case Anim.EffectsDefault:   return 200
            case Anim.EffectsSlow:      return 300
            case Anim.Emphasized:
            case Anim.EmphasizedAccel:
            case Anim.EmphasizedDecel:  return 400
            case Anim.Standard:
            case Anim.StandardAccel:
            case Anim.StandardDecel:    return 400
            case Anim.Progress:         return 300
            case Anim.Bounce:           return 600
        }
    }
}

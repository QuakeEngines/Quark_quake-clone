"""   QuArK  -  Quake Army Knife

Model editor views, grid scale numbering feature.
"""
#
# Copyright (C) 1996-99 Armin Rigo
# THIS FILE IS PROTECTED BY THE GNU GENERAL PUBLIC LICENCE
# FOUND IN FILE "COPYING.TXT"
#

Info = {
   "plug-in":       "Display grid scale",
   "desc":          "Displays the grid scale in the 2D viewing windows. Activate from the 'Options' menu",
   "date":          "April 27 2007",
   "author":        "cdunde",
   "author e-mail": "cdunde@sbcglobal.net",
   "quark":         "Version 6.5 Beta 2.0" }

import quarkpy.mdloptions
from quarkpy.mdlutils import *

#
# -------- grid numbering routines
#

def NumberGrid(cv, view, text):
    "function to place numbers on grid"
    editor = mapeditor()
    cv.textout(view.y, view.z, text)

#
# This part is a magical incantation.
# First the normal arguments for
#  finishdrawing, then the oldfinish=... stuff,
#  which has the effect of storing the current
#  finishdrawing method inside this function as
#  the value of the oldfinish variable.
# These def statements are executed as the plugins are being
#  loaded, but not reexecuted in later operations
#  of the map editor, only the functions they define are.
#

def gridfinishdrawing(editor, view, gridoldfinish=quarkpy.mdleditor.ModelEditor.finishdrawing):

    #
    # execute the old method
    #

    gridoldfinish(editor, view)

    # Stops jerky movement during panning in 2D views.
    from quarkpy.qbaseeditor import flagsmouse
    if (flagsmouse == 528 or flagsmouse == 1040):
        view.handles = []

    if editor.ModelFaceSelList != []:
        quarkpy.mdlhandles.ModelFaceHandle(quarkpy.qhandles.GenericHandle).draw(editor, view, editor.EditorObjectList)

# The following sets the canvas function to draw the images.

    cv = view.canvas()

    grid = editor.gridstep         # Gives grid setting
    gridunits = quarkx.ftos(grid)  # Converts float nbr to string
    type = view.info["type"]       # These type values are set
                                   #  in the layout-defining plugins.
# ===============
# X view settings
# ===============

    if type == "YZ":

        if not MdlOption("All2DviewsScale") and not MdlOption("AllScalesCentered") and not MdlOption("XviewScale") and not MdlOption("XyScaleCentered") and not MdlOption("XzScaleCentered"):
            return
        if grid == 0:
            return

        cv.fontcolor = RED
        cv.fontsize = 8

        YZarea = `view.clientarea`       # Gets the view area as a string
        pixels = YZarea.replace("(","")  # trims ( from YZarea
        pixels = pixels.replace(")","")  # trims ) from YZarea
        pixels = pixels.split(",")       # trims , from YZarea
        Ystring = pixels[0]              # pulls out y factor string
        Zstring = pixels[1].strip()      # pulls out z factor string
        Ypixels = int(Ystring)           # converts y string to intiger nbr
        Zpixels = int(Zstring)           # converts z string to intiger nbr
        highlight = int(quarkx.setupsubset(SS_MODEL, "Display")["GridHighlight"])
        Ygroups = ((Ypixels/(grid * 1.0)) / view.scale()) / highlight
        Zgroups = ((Zpixels/(grid * 1.0)) / view.scale()) / highlight
        pixspergroup = Zpixels / Zgroups
        Ycounter = 1
        Zcounter = 1
        Ygroup = (Ypixels / Ygroups)
        Zgroup = (Zpixels / Zgroups)
        if Ygroup < 20:return
        units = (grid * highlight)
        Ystring = quarkx.ftos(0)
        Zstring = quarkx.ftos(0)


        if not MdlOption("XyScaleCentered") and not MdlOption("AllScalesCentered"):
            if not MdlOption("AxisXYZ"):
                Yviewcenter = 6
            else:
                Yviewcenter = 48
        else:
            if not MdlOption("All2DviewsScale") and not MdlOption("XviewScale"):
                Yviewcenter = (Ypixels/2)+4
            else:
                Yviewcenter = 0


        if not MdlOption("XzScaleCentered") and not MdlOption("AllScalesCentered"):
            Zviewcenter = (Zpixels)-12
        else:
            Zviewcenter = (Zpixels/2)-4
        Ygroup1 = Yviewcenter+2
        Zgroup1 = Zviewcenter
        cv.brushstyle = BS_CLEAR
        cv.fontname = "Terminal"
        cv.textout(Yviewcenter, 2, "Y " + Ystring)
        cv.textout(Yviewcenter, 16, "  l")      # for mark line
        cv.textout(0, Zviewcenter, " Z " + Zstring + " --") # for mark line
        Ytotal =  (units * 2)
        Ztotal =  units
        if pixspergroup > 40:
            Zgroup = Zgroup/2
            Ztotal = Ztotal/2
            units = units/2
        if pixspergroup > 80:
            Zgroup = Zgroup/2
            Ztotal = Ztotal/2
            units = units/2
        if pixspergroup > 160:
            Zgroup = Zgroup/2
            Ztotal = Ztotal/2
            units = units/2
        while 1:
            if Zcounter > 11:
               break
            else:
                Zstring =  quarkx.ftos(Ztotal)
                Znextgroupup = Zgroup1 - (Zgroup * Zcounter)
                Znextgroupup = int(Znextgroupup)
                if Znextgroupup > 19:
                    cv.textout(0, Znextgroupup, " " + Zstring + " --")
                Znextgroupdown = Zgroup1 + (Zgroup * Zcounter)
                Znextgroupdown = int(Znextgroupdown)
                cv.textout(0, Znextgroupdown, "-" + Zstring + " --")
                Zcounter = Zcounter + 1
                Ztotal = Ztotal + units

        if pixspergroup > 40:
            Ygroup = Ygroup/2
            Ytotal = Ytotal/2
        if pixspergroup > 80:
            Ygroup = Ygroup/2
            Ytotal = Ytotal/2
        if pixspergroup > 160:
            Ygroup = Ygroup/2
            Ytotal = Ytotal/2
        if pixspergroup > 320:
            Ygroup = Ygroup/2
            Ytotal = Ytotal/2
            units = units*.5
        while 1:
            if Ycounter > 7:
                break
            else:
                Ystring =  quarkx.ftos(Ytotal)
                Ynextgroupleft = Ygroup1 - ((Ygroup*2) * Ycounter)
                Ynextgroupleft = int(Ynextgroupleft)
                if not MdlOption("AxisXYZ"):
                    cv.textout(Ynextgroupleft-2, 2, Ystring)
                    cv.textout(Ynextgroupleft-2, 16, "  l")
                else:
                    if Ynextgroupleft > 40:
                        cv.textout(Ynextgroupleft-2, 2, Ystring)
                        cv.textout(Ynextgroupleft-2, 16, "  l")
                Ynextgroupright = Ygroup1 + ((Ygroup*2) * Ycounter)
                Ynextgroupright = int(Ynextgroupright)
                cv.textout(Ynextgroupright+4, 2, "-" + Ystring)
                cv.textout(Ynextgroupright-2, 16, "  l")
                cv.textout(Ynextgroupleft-2, 16, "  l")
                Ycounter = Ycounter + 1
                Ytotal = Ytotal + (units*2)

# ===============
# Y view settings
# ===============

    elif type == "XZ":

        if not MdlOption("All2DviewsScale") and not MdlOption("AllScalesCentered") and not MdlOption("YviewScale") and not MdlOption("YxScaleCentered") and not MdlOption("YzScaleCentered"):
            return
        if grid == 0:
            return

        cv.fontcolor = RED
        cv.fontsize = 8

        XZarea = `view.clientarea`
        pixels = XZarea.replace("(","")
        pixels = pixels.replace(")","")
        pixels = pixels.split(",")
        Xstring = pixels[0]
        Zstring = pixels[1].strip()
        Xpixels = int(Xstring)
        Zpixels = int(Zstring)
        highlight = int(quarkx.setupsubset(SS_MODEL, "Display")["GridHighlight"])
        Xgroups = ((Xpixels/(grid * 1.0)) / view.scale()) / highlight
        Zgroups = ((Zpixels/(grid * 1.0)) / view.scale()) / highlight
        pixspergroup = Zpixels / Zgroups
        Xcounter = 1
        Zcounter = 1
        Xgroup = (Xpixels / Xgroups)
        Zgroup = (Zpixels / Zgroups)
        if Xgroup < 20:return
        units = (grid * highlight)
        Xstring = quarkx.ftos(0)
        Zstring = quarkx.ftos(0)
        



        if not MdlOption("YxScaleCentered") and not MdlOption("AllScalesCentered"):
            if not MdlOption("AxisXYZ"):
                Xviewcenter = 16
            else:
                Xviewcenter = 48
        else:
            if not MdlOption("All2DviewsScale") and not MdlOption("YviewScale"):
                Xviewcenter = (Xpixels/2)+4
            else:
                Xviewcenter = 0


       
        if not MdlOption("YzScaleCentered") and not MdlOption("AllScalesCentered"):
            Zviewcenter = (Zpixels)-12
        else:
            Zviewcenter = (Zpixels/2)-4
        Xgroup1 = Xviewcenter+2
        Zgroup1 = Zviewcenter
        cv.brushstyle = BS_CLEAR
        cv.fontname = "Terminal"
        cv.textout(Xviewcenter, 2, "X " + Xstring)
        cv.textout(Xviewcenter, 16, "  l")      # for mark line      
        if MdlOption("RedLines2") and not MdlOption("AllScalesCentered") and not MdlOption("YzScaleCentered"):
            cv.textout(10, Zviewcenter, " Z " + Zstring + " --")
        else:
            cv.textout(0, Zviewcenter, " Z " + Zstring + " --")
        Xtotal =  (units * 2)
        Ztotal =  units
        if pixspergroup > 40:
            Zgroup = Zgroup/2
            Ztotal = Ztotal/2
            units = units/2
        if pixspergroup > 80:
            Zgroup = Zgroup/2
            Ztotal = Ztotal/2
            units = units/2
        if pixspergroup > 160:
            Zgroup = Zgroup/2
            Ztotal = Ztotal/2
            units = units/2
        while 1:
            if Zcounter > 11:
               break
            else:
                Zstring =  quarkx.ftos(Ztotal)
                Znextgroupup = Zgroup1 - (Zgroup * Zcounter)
                Znextgroupup = int(Znextgroupup)
                if Znextgroupup > 19:
                    cv.textout(0, Znextgroupup, " " + Zstring + " --")
                Znextgroupdown = Zgroup1 + (Zgroup * Zcounter)
                Znextgroupdown = int(Znextgroupdown)
                cv.textout(0, Znextgroupdown, "-" + Zstring + " --")
                Zcounter = Zcounter + 1
                Ztotal = Ztotal + units

        if pixspergroup > 40:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
        if pixspergroup > 80:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
        if pixspergroup > 160:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
        if pixspergroup > 320:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
            units = units*.5
        while 1:
            if Xcounter > 7:
                break
            else:
                Xstring =  quarkx.ftos(Xtotal)
                Xnextgroupleft = Xgroup1 - ((Xgroup*2) * Xcounter)
                Xnextgroupleft = int(Xnextgroupleft)
                if not MdlOption("AxisXYZ"):
                    cv.textout(Xnextgroupleft-2, 2, "-" + Xstring)
                    cv.textout(Xnextgroupleft-2, 16, "  l") # new for line
                else:
                    if Xnextgroupleft > 40:
                        cv.textout(Xnextgroupleft-2, 2, "-" + Xstring)
                        cv.textout(Xnextgroupleft-2, 16, "  l") # new for line
                Xnextgroupright = Xgroup1 + ((Xgroup*2) * Xcounter)
                Xnextgroupright = int(Xnextgroupright)
                cv.textout(Xnextgroupright+4, 2, Xstring)
                cv.textout(Xnextgroupright-2, 16, "  l")  # for mark line
                cv.textout(Xnextgroupleft-2, 16, "  l")   # for mark line
                Xcounter = Xcounter + 1
                Xtotal = Xtotal + (units*2)

# ===============
# Z view settings
# ===============

    elif type == "XY":

        if not MdlOption("All2DviewsScale") and not MdlOption("AllScalesCentered") and not MdlOption("ZviewScale") and not MdlOption("ZxScaleCentered") and not MdlOption("ZyScaleCentered"):
            return
        if grid == 0:
            return

        cv.fontcolor = RED
        cv.fontsize = 8

        XZarea = `view.clientarea`
        pixels = XZarea.replace("(","")
        pixels = pixels.replace(")","")
        pixels = pixels.split(",")
        Xstring = pixels[0]
        Ystring = pixels[1].strip()
        Xpixels = int(Xstring)
        Ypixels = int(Ystring)
        highlight = int(quarkx.setupsubset(SS_MODEL, "Display")["GridHighlight"])
        Xgroups = ((Xpixels/(grid * 1.0)) / view.scale()) / highlight
        Ygroups = ((Ypixels/(grid * 1.0)) / view.scale()) / highlight
        pixspergroup = Ypixels / Ygroups
        Xcounter = 1
        Ycounter = 1
        Xgroup = (Xpixels / Xgroups)
        Ygroup = (Ypixels / Ygroups)
        if Xgroup < 20:return
        units = (grid * highlight)
        Xstring = quarkx.ftos(0)
        Ystring = quarkx.ftos(0)



        if not MdlOption("ZxScaleCentered") and not MdlOption("AllScalesCentered"):
            if not MdlOption("AxisXYZ"):
                Xviewcenter = 16
            else:
                Xviewcenter = 48
        else:
            if not MdlOption("All2DviewsScale") and not MdlOption("ZviewScale"):
                Xviewcenter = (Xpixels/2)+4
            else:
                Xviewcenter = 0


        if not MdlOption("ZyScaleCentered") and not MdlOption("AllScalesCentered"):
            Yviewcenter = (Ypixels)-12
        else:
            Yviewcenter = (Ypixels/2)-4
        Xgroup1 = Xviewcenter+2
        Ygroup1 = Yviewcenter
        cv.brushstyle = BS_CLEAR
        cv.fontname = "Terminal"
        cv.textout(Xviewcenter, 2, "X " + Xstring)
        cv.textout(Xviewcenter, 16, "  l")      # new for mark line
        if not MdlOption("AllScalesCentered") and not MdlOption("ZyScaleCentered"):
            cv.textout(10, Yviewcenter, " Y " + Ystring + " --") # for mark line
        else:
            cv.textout(0, Yviewcenter, " Y " + Ystring + " --")  # for mark line
        Xtotal =  (units * 2)
        Ytotal =  units
        if pixspergroup > 40:
            Ygroup = Ygroup/2
            Ytotal = Ytotal/2
            units = units/2
        if pixspergroup > 80:
            Ygroup = Ygroup/2
            Ytotal = Ytotal/2
            units = units/2
        if pixspergroup > 160:
            Ygroup = Ygroup/2
            Ytotal = Ytotal/2
            units = units/2
        while 1:
            if Ycounter > 11:
               break
            else:
                Ystring =  quarkx.ftos(Ytotal)
                Ynextgroupup = Ygroup1 - (Ygroup * Ycounter)
                Ynextgroupup = int(Ynextgroupup)
                if Ynextgroupup > 19:
                    cv.textout(0, Ynextgroupup, " " + Ystring + " --")
                Ynextgroupdown = Ygroup1 + (Ygroup * Ycounter)
                Ynextgroupdown = int(Ynextgroupdown)
                cv.textout(0, Ynextgroupdown, "-" + Ystring + " --")
                Ycounter = Ycounter + 1
                Ytotal = Ytotal + units

        if pixspergroup > 40:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
        if pixspergroup > 80:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
        if pixspergroup > 160:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
        if pixspergroup > 320:
            Xgroup = Xgroup/2
            Xtotal = Xtotal/2
            units = units*.5
        while 1:
            if Xcounter > 7:
                break
            else:
                Xstring =  quarkx.ftos(Xtotal)
                Xnextgroupleft = Xgroup1 - ((Xgroup*2) * Xcounter)
                Xnextgroupleft = int(Xnextgroupleft)
                if not MdlOption("AxisXYZ"):
                    cv.textout(Xnextgroupleft-2, 2, "-" + Xstring)
                    cv.textout(Xnextgroupleft-2, 16, "  l")      # for mark line
                else:
                    if Xnextgroupleft > 40:
                        cv.textout(Xnextgroupleft-2, 2, "-" + Xstring)
                        cv.textout(Xnextgroupleft-2, 16, "  l")  # for mark line
                Xnextgroupright = Xgroup1 + ((Xgroup*2) * Xcounter)
                Xnextgroupright = int(Xnextgroupright)
                cv.textout(Xnextgroupright+4, 2, Xstring)
                cv.textout(Xnextgroupright-2, 16, "  l")     # for mark line
                cv.textout(Xnextgroupleft-2, 16, "  l")      # for mark line
                Xcounter = Xcounter + 1
                Xtotal = Xtotal + (units*2)

    else:
       return

#
# Now set our new function as the finishdrawing method.
#

quarkpy.mdleditor.ModelEditor.finishdrawing = gridfinishdrawing


# ********* This creates the Options menu 2D grid items ***************


def All2DviewsClick(m):
    editor = mapeditor()
    if not MdlOption("All2DviewsScale"):
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['XviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['XyScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['XzScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['YviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['YxScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['YzScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['ZviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['ZxScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['ZyScaleCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def All2DviewsScalesCentered(m):
    editor = mapeditor()
    if not MdlOption("AllScalesCentered"):
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['XviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['XzScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['YviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['XyScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['YxScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['YzScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['ZviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['ZxScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['ZyScaleCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def XviewScaleClick(m):
    editor = mapeditor()
    if not MdlOption("XviewScale"):
        quarkx.setupsubset(SS_MODEL, "Options")['XviewScale'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['XyScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['XzScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['XviewScale'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def XviewYScaleCentered(m):
    editor = mapeditor()
    if not MdlOption("XyScaleCentered"):
        quarkx.setupsubset(SS_MODEL, "Options")['XyScaleCentered'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['XviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['XyScaleCentered'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def XviewZScaleCentered(m):
    editor = mapeditor()
    if not MdlOption("XzScaleCentered"):
        quarkx.setupsubset(SS_MODEL, "Options")['XzScaleCentered'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['XviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['XzScaleCentered'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def YviewScaleClick(m):
    editor = mapeditor()
    if not MdlOption("YviewScale"):
        quarkx.setupsubset(SS_MODEL, "Options")['YviewScale'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['YxScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['YzScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['YviewScale'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def YviewXScaleCentered(m):
    editor = mapeditor()
    if not MdlOption("YxScaleCentered"):
        quarkx.setupsubset(SS_MODEL, "Options")['YxScaleCentered'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['YviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['YxScaleCentered'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def YviewZScaleCentered(m):
    editor = mapeditor()
    if not MdlOption("YzScaleCentered"):
        quarkx.setupsubset(SS_MODEL, "Options")['YzScaleCentered'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['YviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['YzScaleCentered'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def ZviewScaleClick(m):
    editor = mapeditor()
    if not MdlOption("ZviewScale"):
        quarkx.setupsubset(SS_MODEL, "Options")['ZviewScale'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['ZxScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['ZyScaleCentered'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['ZviewScale'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def ZviewXScaleCentered(m):
    editor = mapeditor()
    if not MdlOption("ZxScaleCentered"):
        quarkx.setupsubset(SS_MODEL, "Options")['ZxScaleCentered'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['ZviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['ZxScaleCentered'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)


def ZviewYScaleCentered(m):
    editor = mapeditor()
    if not MdlOption("ZyScaleCentered"):
        quarkx.setupsubset(SS_MODEL, "Options")['ZyScaleCentered'] = "1"
        quarkx.setupsubset(SS_MODEL, "Options")['ZviewScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['All2DviewsScale'] = None
        quarkx.setupsubset(SS_MODEL, "Options")['AllScalesCentered'] = None
    else:
        quarkx.setupsubset(SS_MODEL, "Options")['ZyScaleCentered'] = None
    quarkpy.mdlutils.Update_Editor_Views(editor, 6)



def View2DgridMenu(editor):

    X0 = quarkpy.qmenu.item("All 2D views", All2DviewsClick, "|All 2D views:\n\nIf this menu item is checked, it will display a scale of the current grid setting in all 2D views and deactivate this menu's individual items.|intro.modeleditor.menu.html#optionsmenu")

    X1 = quarkpy.qmenu.item("   all scales centered", All2DviewsScalesCentered, "|all scales centered:\n\nIf this menu item is checked, it will display a scale of the current grid setting centered in all 2D views and deactivate this menu's individual items.|intro.modeleditor.menu.html#optionsmenu")

    X2 = quarkpy.qmenu.item("X-Back 2D view", XviewScaleClick, "|X-Back 2D view:\n\nIf this menu item is checked, it will display a scale of the current grid setting in the ' X - Back ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X3 = quarkpy.qmenu.item("   y scale centered", XviewYScaleCentered, "|y scale centered:\n\nIf this menu item is checked, it will display a scale of the current grid setting centered in the ' X - Face ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X4 = quarkpy.qmenu.item("   z scale centered", XviewZScaleCentered, "|z scale centered:\n\nIf this menu item is checked, it will display a scale of the current grid setting centered in the ' X - Face ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X5 = quarkpy.qmenu.item("Y-Side 2D view", YviewScaleClick, "|Y-Side 2D view:\n\nIf this menu item is checked, it will display a scale of the current grid setting in the ' Y-Side ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X6 = quarkpy.qmenu.item("   x scale centered", YviewXScaleCentered, "|x scale centered:\n\nIf this menu item is checked, it will display a scale of the current grid setting centered in the ' Y-Side ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X7 = quarkpy.qmenu.item("   z scale centered", YviewZScaleCentered, "|z scale centered:\n\nIf this menu item is checked, it will display a scale of the current grid setting centered in the ' Y-Side ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X8 = quarkpy.qmenu.item("Z-Top 2D view", ZviewScaleClick, "|Z-Top 2D view:\n\nIf this menu item is checked, it will display a scale of the current grid setting in the ' Z-Top ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X9 = quarkpy.qmenu.item("   x scale centered", ZviewXScaleCentered, "|x scale centered:\n\nIf this menu item is checked, it will display a scale of the current grid setting centered in the ' Z-Top ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")

    X10 = quarkpy.qmenu.item("   y scale centered", ZviewYScaleCentered, "|y scale centered:\n\nIf this menu item is checked, it will display a scale of the current grid setting centered in the ' Z-Top ' 2D view and deactivate this menu's conflicting item(s) such as  'All 2D views'  if they are currently checked.|intro.modeleditor.menu.html#optionsmenu")


    menulist = [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9, X10]

    items = menulist
    X0.state = quarkx.setupsubset(SS_MODEL,"Options").getint("All2DviewsScale")
    X1.state = quarkx.setupsubset(SS_MODEL,"Options").getint("AllScalesCentered")
    X2.state = quarkx.setupsubset(SS_MODEL,"Options").getint("XviewScale")
    X3.state = quarkx.setupsubset(SS_MODEL,"Options").getint("XyScaleCentered")
    X4.state = quarkx.setupsubset(SS_MODEL,"Options").getint("XzScaleCentered")
    X5.state = quarkx.setupsubset(SS_MODEL,"Options").getint("YviewScale")
    X6.state = quarkx.setupsubset(SS_MODEL,"Options").getint("YxScaleCentered")
    X7.state = quarkx.setupsubset(SS_MODEL,"Options").getint("YzScaleCentered")
    X8.state = quarkx.setupsubset(SS_MODEL,"Options").getint("ZviewScale")
    X9.state = quarkx.setupsubset(SS_MODEL,"Options").getint("ZxScaleCentered")
    X10.state = quarkx.setupsubset(SS_MODEL,"Options").getint("ZyScaleCentered")

    return menulist


# ******************Creates the Popup menu********************

def ViewAmendMenu1click(m):
    editor = mapeditor(SS_MODEL)
    if editor is None: return
    m.items = View2DgridMenu(editor)


GridMenuCmds = [quarkpy.qmenu.popup("Grid scale in 2D views", [], ViewAmendMenu1click, "|Grid scale in 2D views:\n\nThese functions allow you to display a scale of the current grid setting in any one, combination, or all of the 2D views of the Editor.", "intro.modeleditor.menu.html#optionsmenu")]

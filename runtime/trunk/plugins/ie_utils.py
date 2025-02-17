"""   QuArK  -  Quake Army Knife

Various Model importer\exporter utility functions.
"""
#
# Copyright (C) 1996-99 Armin Rigo
# THIS FILE IS PROTECTED BY THE GNU GENERAL PUBLIC LICENCE
# FOUND IN FILE "COPYING.TXT"
#

import os, os.path, time, operator
import quarkx
import quarkpy.qutils

# Globals
SS_MODEL = 3
logging = 0
textlog = "model_ie_log.txt"
tobj = None

'''
NOTE: ALL IMPORTERS AND EXPORTERS SHOULD INCLUDE THIS LOGGING CODE.

1) To add logging to an importer or exporter put these lines near the top, under the file header, in this order:
import os, time, operator
import ie_utils
from ie_utils import tobj

# Globals
logging = 0
exportername = "ie_md2_export.py" (or importername = "ie_md2_import.py" depending on which one you're doing)
textlog = "md2_ie_log.txt"

2) Then add needed globals and calls to start and end the logging in your main file function like this:
def save_md2(filename):
    global tobj, logging, exportername, textlog ### Needed globals.
    ### Next line starts the logging.
    logging, tobj, starttime = ie_utils.default_start_logging(exportername, textlog, filename, "EX") ### Use "EX" for exporter text, "IM" for importer text.

    ### Line below here saves the model (just for this example---DO NOT COPY NEXT LINE).
    fill_md2(md2, component)

    ### Next line is optional, it adds additional text at the bottom of the default message,
    ### with a blank line between them. If none then just exclude it from the function arguments below.
    add_to_message = "Any used skin textures that are not a .pcx\nwill need to be created to go with the model"
    ### Next line ends the logging.
    ie_utils.default_end_logging(filename, "EX", starttime, add_to_message) ### Use "EX" for exporter text, "IM" for importer text.


3) Then in any function you want logging declair the global and call for tobj like this: (all items must be strings)
def fill_md2(md2, component):
    global tobj
    if logging == 1:
        tobj.logcon ("#####################################################################")
        tobj.logcon ("Skins group data: " + str(md2.num_skins) + " skins")
        tobj.logcon ("#####################################################################")
        tobj.logcon ("")

'''


def default_start_logging(IM_EX_name, IM_EX_textlog, filename, IM_or_EX, add_to_message=""):
    global tobj, textlog

    starttime = time.time()
    if quarkx.setupsubset(SS_MODEL, "Options")['IELogging'] != "0":
        logging = 1
        if quarkx.setupsubset(SS_MODEL, "Options")['IELogByFileType'] != "1" and textlog != "model_ie_log.txt" and tobj is not None:
            if tobj.txtobj is not None:
                tobj.txtobj.close()
                textlog = "model_ie_log.txt"
                tobj = dotext(textlog) # Calls the class to handle logging.

        if quarkx.setupsubset(SS_MODEL, "Options")['IELogByFileType'] == "1" and textlog == "model_ie_log.txt" and tobj is not None:
            if tobj.txtobj is not None:
                tobj.txtobj.close()
                textlog = IM_EX_textlog
                tobj = dotext(textlog) # Calls the class to handle logging.

        if quarkx.setupsubset(SS_MODEL, "Options")['IELogAll'] != "1":
            if quarkx.setupsubset(SS_MODEL, "Options")['IELogByFileType'] != "1":
                textlog = "model_ie_log.txt"
                tobj = dotext(textlog) # Calls the class to handle logging.
            else:
                textlog = IM_EX_textlog
                tobj = dotext(textlog) # Calls the class to handle logging.
        else:
            if tobj is None:
                if quarkx.setupsubset(SS_MODEL, "Options")['IELogByFileType'] != "1":
                    textlog = "model_ie_log.txt"
                    tobj = dotext(textlog) # Calls the class to handle logging.
                else:
                    textlog = IM_EX_textlog
                    tobj = dotext(textlog) # Calls the class to handle logging.

        if IM_or_EX == "IM":
            tobj.logcon ("#####################################################################")
            tobj.logcon ("This is: %s" % IM_EX_name)
            tobj.logcon ("Importing file:")
            tobj.logcon (filename)
            if add_to_message == "":
                tobj.logcon ("#####################################################################")
            else:
                tobj.logcon ("")
                add2log = add_to_message.split('\n')
                for item in add2log:
                    tobj.logcon (item)
                tobj.logcon ("#####################################################################")
        else:
            tobj.logcon ("#####################################################################")
            tobj.logcon ("This is: %s" % IM_EX_name)
            tobj.logcon ("Exporting file:")
            tobj.logcon (filename)
            if add_to_message == "":
                tobj.logcon ("#####################################################################")
            else:
                tobj.logcon ("")
                add2log = add_to_message.split('\n')
                for item in add2log:
                    tobj.logcon (item)
                tobj.logcon ("#####################################################################")
    else:
        logging = 0

    return logging, tobj, starttime


def default_end_logging(filename, IM_or_EX, starttime, add_to_message=""):
    global tobj

    end = time.time()
    seconds = "in %.2f %s" % (end-starttime, "seconds")
    if quarkx.setupsubset(SS_MODEL, "Options")['IELogging'] != "0":
        if IM_or_EX == "IM":
            tobj.logcon ("=====================================================================")
            tobj.logcon ("Successfully imported " + os.path.basename(filename))
            tobj.logcon (seconds + " " + time.asctime(time.localtime()))
            if add_to_message == "":
                tobj.logcon ("=====================================================================")
                tobj.logcon ("")
                tobj.logcon ("")
            else:
                tobj.logcon ("")
                add2log = add_to_message.split('\n')
                for item in add2log:
                    tobj.logcon (item)
                tobj.logcon ("=====================================================================")
                tobj.logcon ("")
                tobj.logcon ("")
            if quarkx.setupsubset(SS_MODEL, "Options")['IELogAll'] != "1":
                tobj.txtobj.close()
        else:
            tobj.logcon ("=====================================================================")
            tobj.logcon ("Successfully exported " + os.path.basename(filename))
            tobj.logcon (seconds + " " + time.asctime(time.localtime()))
            if add_to_message == "":
                tobj.logcon ("=====================================================================")
                tobj.logcon ("")
                tobj.logcon ("")
            else:
                tobj.logcon ("")
                add2log = add_to_message.split('\n')
                for item in add2log:
                    tobj.logcon (item)
                tobj.logcon ("=====================================================================")
                tobj.logcon ("")
                tobj.logcon ("")
            if quarkx.setupsubset(SS_MODEL, "Options")['IELogAll'] != "1":
                tobj.txtobj.close()
    if IM_or_EX == "EX":
        if add_to_message == "":
            message = "Successfully exported " + os.path.basename(filename) + "\n" + seconds + " " + time.asctime(time.localtime())
        else:
            message = "Successfully exported " + os.path.basename(filename) + "\n" + seconds + " " + time.asctime(time.localtime()) + "\n\n" + add_to_message
        quarkx.msgbox(message, quarkpy.qutils.MT_INFORMATION, quarkpy.qutils.MB_OK)



def safestring(st):
    "Makes sure what it gets is a string,"
    "deals with strange chars"

    myst = ""
    for ll in xrange(len(st)):
        if st[ll] < " ":
            myst += "#"
        else:
            myst += st[ll]
    return myst

class dotext:

    _NO = 0    #use internal to class only
    LOG = 1    #write only to LOG
    CON = 2    #write to both LOG and CONSOLE

    def __init__(self, textlog, where=LOG):
        self.textlog = textlog
        self.dwhere = where
        self.txtobj = None

    def write(self, wstring, maxlen=80):
        # Opens a text file in QuArK's main directory for logging to.
        # See QuArK's Defaults.qrk file for additional setup code for IELogging option.
        if quarkx.setupsubset(SS_MODEL, "Options")['IELogging'] != "0":
            if self.txtobj == None or not os.path.exists(quarkx.exepath + self.textlog):
                self.txtobj = open(quarkx.exepath + self.textlog, "w")
        if (self.txtobj==None):
            return
        while (1):
            ll = len(wstring)
            if (ll>maxlen):
                self.txtobj.write((wstring[:maxlen]))
                self.txtobj.write("\n")
                if int(quarkx.setupsubset(SS_MODEL, "Options")['IELogging']) == 2:
                    print (wstring[:maxlen])
                wstring = (wstring[maxlen:])
            else:
                try:
                    self.txtobj.write(wstring)
                except:
                    self.txtobj = open(quarkx.exepath + self.textlog, "w")
                    self.txtobj.write(wstring)
                if int(quarkx.setupsubset(SS_MODEL, "Options")['IELogging']) == 2:
                    if wstring != "\n":
                        print wstring
                break

    def pstring(self, ppstring, where = _NO):
        where = int(quarkx.setupsubset(SS_MODEL, "Options")['IELogging'])
        if where == dotext._NO: where = self.dwhere
        self.write(ppstring)
        self.write("\n")

    def plist(self, pplist, where = _NO):
        self.pprint ("list:[")
        for pp in xrange(len(pplist)):
            self.pprint ("[%d] -> %s" % (pp, pplist[pp]), where)
        self.pprint ("]")

    def pdict(self, pdict, where = _NO):
        self.pprint ("dict:{", where)
        for pp in pdict.keys():
            self.pprint ("[%s] -> %s" % (pp, pdict[pp]), where)
        self.pprint ("}")

    def pprint(self, parg, where = _NO):
        if parg == None:
            self.pstring("_None_", where)
        elif type(parg) == type ([]):
            self.plist(parg, where)
        elif type(parg) == type ({}):
            self.pdict(parg, where)
        else:
            self.pstring(safestring(str(parg)), where)

    def logcon(self, parg):
        self.pprint(parg, dotext.CON)

"""
NOTE: ALL IMPORTERS AND EXPORTERS SHOULD INCLUDE THIS PATH CHECKING CODE.

1) To add path checking to an importer or exporter put this line near the top:
import ie_utils

2) Call for the path check like this:
def loadmodel(root, filename, gamename, nomessage=0):
    ### First we test for a valid (proper) model path.
    basepath = ie_utils.validpath(filename)
    if basepath is None:
        return

"""

def validpath(filename):
    "Tests for a proper model path."

    basepath = ""
    name = filename.split('\\')
    for word in name:
        if word == "models":
            break
        basepath = basepath + word + "\\"
    if not filename.find(basepath + "models\\") != -1:
        quarkx.beep() # Makes the computer "Beep" once if folder structure is not valid.
        quarkx.msgbox("Invalid Path Structure!\n\nThe location of a model must be in the\n    'gamefolder\\models' sub-folder.\n\nYour model selection to import shows this path:\n\n" + filename + "\n\nPlace this model or model's folder within the game's 'models' sub-folder\nor make a main folder with a 'models' sub-folder\nand place this model or model's folder in that sub-folder.\n\nThen re-select it for importing.\n\nAny added textures needed half to also be placed\nwithin the 'game' folder using their proper sub-folders.", quarkpy.qutils.MT_ERROR, quarkpy.qutils.MB_OK)
        return None
    else:
        return basepath


# We want this -0.0000003936 as a string, but it gives this -3.936e-007
# So this function creates the proper string and removes zeros from the end.
def NicePrintableFloat(amt):
    amt = round(amt, 10)
    amt = str(amt)
    if amt.find("e") != -1:
        nbr = ""
        if amt.startswith("-"):
            nbr = nbr + "-"
        fix = amt.replace("-", "").replace(".", "").split("e")
        fix[1] = int(fix[1])-1
        amt = nbr + "0." + "0" * fix[1] + fix[0]
    amt = amt.rstrip("0")
    amt = amt.rstrip(".")
    return amt

"""   QuArK  -  Quake Army Knife

Map Duplicator abstract classes.
"""
#
# Copyright (C) 1996-99 Armin Rigo
# THIS FILE IS PROTECTED BY THE GNU GENERAL PUBLIC LICENCE
# FOUND IN FILE "COPYING.TXT"
#

#
# Duplicators are really implemented in the plug-in "mapdups.py".
#
# Each Duplicator type, as determined by its Specific "macro",
# is implemented by a class that inherits from DuplicatorManager.
#


from maputils import *
import maphandles
import mapentities


# Variable icons for Duplicator objects
ico_dict['ico_mapdups'] = LoadIconSet("images\\mapdups", 16)

class DuplicatorManager:
    "Abstract base class for Duplicators."

    Icon = (ico_objects, iiDuplicator)    # defaults

    def buildimages(self, singleimage=None):
        s = self.dup["macro"]
        if type(s)!=type(""):
            s = "(void)"
        print "Note: Unknown Duplicator macro '%s'" % s

    def applylinear(self, matrix, direct=0):
        pass    # abstract

    def sourcelist(self):
        "Build the list of source objects the Duplicator has to work on."
        # This might be modified, but keep in mind that Duplicators
        # should never use objects outside the group they are in, because
        # QuArK does not call buildimages() again when these objects are
        # modified by the user.
        myself = self.dup
        list = myself.subitems
        if myself["out"] and not (myself.parent is None):
             # add "sibling" objects, i.e. the ones in the same group as the Duplicator itself
            for item in myself.parent.subitems:
                if item!=myself and (item.type!=':d' or DupManager(item).siblingincluded(myself)):
                    list.append(item)
        return list

    def siblingincluded(self, other):
        # Should the Duplicator be included into the copies
        # made by another Duplicator in the same group ?
        # By default, only "inner" Duplicators should be.
        return not self.dup["out"]

    def dataformname(self):
        return self.dup["macro"]

    def handles(self, editor, view):
        return maphandles.CenterEntityHandle(self.dup, view, CenterDupHandle)


def is_digit(s):
    if len(s)==1:
        if '0123456789'.find(s)>=0:
            return True
    return False

def get_suffix(s):
    l = len(s)
    for i in range(l):
        j=i
        if not is_digit(s[l-i-1]):
            break
    return s[:l-j], s[l-j:l]

def poolitems(item):
    # Decker: Finding all subitems of type ":d", also automatically finds subitems of type ":e"
    #         This is a "bug" in the QuArK.EXE, caused by having the Duplicator-class inherit from
    #         the Entity-class. Not easy to fix in the QuArK.EXE, so the solution here is to not
    #         search for ":e" types, but have them found when searching for ":d" types.
 #   return item.findallsubitems("",":b")+item.findallsubitems("",":d") #+item.findallsubitems("",":e")
    # cdunde 8-11-05: Reversed to allow entities to work again, apparently fixed elsewhere to correct above.
    return item.findallsubitems("",":b")+item.findallsubitems("",":d")+item.findallsubitems("",":e")

def pool_specs(list):
    specs = {}
    for item in list:
        for item2 in poolitems(item):
            for key in item2.dictspec.keys():
                if not specs.has_key(key):
                    specs[key]="1"
    return specs.keys()

#
# This is a cache for texture-substitution lists
#
Dup_Tex_Dicts={}

class StandardDuplicator(DuplicatorManager):
    "Base for Duplicators that applies on each item one by one."

    Icon = (ico_dict['ico_mapdups'], 0)

    def readvalues(self):
        self.origin = self.dup.origin
        if self.origin is None:
            self.origin = quarkx.vect(0,0,0)
        tex_sub=self.dup["tex_sub"]
        #
        # try to cache the texsub info in a dictionary
        #   attached to the DuplicatorManager class
        #
        if tex_sub:
            if not Dup_Tex_Dicts.has_key(tex_sub):
                tex_dict={}
                try:
                    texfile=open(quarkx.exepath+tex_sub,'r')
                    try:
                        line=texfile.readline()
                        while line:
                            line = line.split()
                            tex_dict[line[0]]=line[:]
                            line=texfile.readline()
                    finally:
                        texfile.close()
                    Dup_Tex_Dicts[tex_sub]=tex_dict
                except (IOError):
                    quarkx.msgbox("Unable to read the texture substitution file "+quarkx.exepath+tex_sub, MT_WARNING, MB_OK)
        sourcelist = self.sourcelist()
        #
        # fancy linear mappings stuff
        #
        if self.dup["offset dup"]=="1":
           box=quarkx.boundingboxof(sourcelist)
           if box is not None:
               self.sourcecenter = 0.5*(box[0]+box[1])
           else:
               self.sourcecenter = None
        
        s = self.dup["offset"]
        if s:
            self.offset = quarkx.vect(s)
        else:
            self.offset = None
        self.matrix = None
        #
        # serializing specifics stuff
        #
        if self.dup["increment suffix"]=="1":
            if self.dup["increment by"]:
                self.incrementby=int(self.dup["increment by"])
            else:
                self.incrementby=1
            #
            # Deciding which get increment suffixed
            #
            if self.dup["increment all target"] is not None:
                specs = pool_specs(sourcelist)
                incrementable = []
                for spec in specs:
                    if spec.find("target")>=0:
                        incrementable.append(spec)
            else:
                incrementable = ["target", "targetname", "killtarget", "Data.KeyPointName"]
            #
            # Final values and custom increments
            #
            self.final_specs={}
            self.incre_specs={}
            for spec in self.dup.dictspec.keys():
                if self.dup[spec]!="":
                    if spec.find('final_')==0:
                        spec2=spec[6:]
                        val = self.dup[spec]
                        #
                        # value specifies a different final value
                        #   for each incrementable base
                        #
                        if val.find(':')>=0:
                            dict = {}
                            pairs = val.split()
                            for pair in pairs:
                                attr, val = pair.split(":")
                                attr, val = attr.strip(), val.strip()
                                dict[attr]=val
                            self.final_specs[spec2]=dict
                        #
                        # ordinary, one value
                        #
                        else:
                            self.final_specs[spec2]=val
                if spec.find('incre_')==0:
                    spec2=spec[6:]
                    self.incre_specs[spec2]=int(self.dup[spec])
                    if not spec2 in incrementable:
                        incrementable.append(spec2)
            moreserial = self.dup["incrementable specifics"]
            if moreserial is not None:
                incrementable=incrementable+moreserial.split()
            self.incrementable=incrementable

    def applylinear(self, matrix, direct=0):
        s = self.dup["offset"]
        if s:
            self.dup["offset"] = str(matrix * quarkx.vect(s))

    def do(self, item):
        "Default code to apply a one-step operation on 'item'."
        if self.dup["offset dup"]=="1":
            if self.sourcecenter is not None:
                item.translate(self.origin-self.sourcecenter)
        if self.offset:
            item.translate(self.offset)
        if self.matrix and not self.dup["item center"]:
            item.linear(self.origin, self.matrix)
        if self.dup["increment suffix"]=="1":
            def get_incr(spec,self=self):
                if self.incre_specs.has_key(spec):
                    return self.incre_specs[spec]
                else:
                    return self.incrementby
            for item2 in poolitems(item):
                for spec in self.incrementable:
                    val = item2[spec]
                    if val is not None and val!="":
                        if is_digit(val[len(val)-1]):
                            base, index = get_suffix(val)
                            width = len(index)
                            index = int(index)+get_incr(spec)
                            index = ` index`.zfill(width)
                            item2[spec]=base+index
        return [item]

    def buildimages(self, singleimage=None):
        try:
            self.readvalues()
        except:
            print "Note: Invalid Duplicator Specific/Args."
            return
        list = self.sourcelist()
        list = map(lambda item:item.copy(), list)
        newobjs = []
        try:
            count = int(self.dup["count"])
        except:
            count = 1
        cumoffset = quarkx.vect(0,0,0)
        if self.dup["offset"]:
            offset = quarkx.vect(self.dup["offset"])
        else:
            offset = cumoffset
        tex_sub=self.dup["tex_sub"]
        tex_dict = None
        if tex_sub:
            try:
                tex_dict=Dup_Tex_Dicts[tex_sub]
            except:
                quarkx.msgbox('no tex_dict found', MT_INFORMATION, MB_OK)
        if self.dup["item center"]:
            try:
                if self.matrix is not None:
                    for item in list:
                        center = maphandles.GetUserCenter(item)
                        item.linear(center, self.matrix)
            except (AttributeError):
                pass
        for i in range(count):
#            debug('i = %d'%i)
            cumoffset = offset+cumoffset
            self.imagenumber = i
            # the following line :
            #  - makes copies of the items in "list";
            #  - calls "self.do" for the copies;
            #  - puts the results of these calls into a list;
            #  - removes all None objects;
            #  - and stores the new list back in "list".
            list = reduce(lambda x,y: x+y, map(lambda item, fn=self.do: fn(item.copy()), list), [])
            if self.dup["item center"]:
                try:
                    if self.matrix is not None:
                        for item in list:
                            center = maphandles.GetUserCenter(item)
                            if item["usercenter"]:
                                center=center+cumoffset
                            item.linear(center, self.matrix)
                except (AttributeError):
                    pass
            #
            # Set final spec values for incrementable suffixes
            #
            if tex_dict:
                for item in list:
                    #
                    # not using replacetex on item so that there can be a flag
                    #   to inhibit texture replacement
                    #
                    surfs=item.findallsubitems("",":f")+item.findallsubitems("",":b2")
                    for surf in surfs:
                        if not surf["notexsub"]:
                            try:
                                if i==0:
                                    orig_tex=surf["orig_tex"]=surf.texturename
                                else:
                                    orig_tex=surf["orig_tex"]
                                texlist=tex_dict[orig_tex]
#                                debug(' i: '+`i`)
                                surf.texturename = texlist[(i+1)%len(texlist)]
#                                debug('   '+surf.texturename)
                            except:
                                pass
                
            if self.dup["increment suffix"]:
                if i==count-1:
                    for item in list:
                        for item2 in poolitems(item):
                            for spec in self.final_specs.keys():
                                if item2[spec]!="" or item2[spec] is not None:
                                    val = self.final_specs[spec]
                                    if val=="None":
                                        item2[spec]=""
                                    #
                                    # dictionary
                                    #
                                    elif type(val)==type({}):
                                       base, index = get_suffix(item2[spec])
                                       if val.has_key(base):
                                           item2[spec]=val[base]
                                    else:
                                        item2[spec]=val
            if (singleimage is None) or (i==singleimage):
                newobjs = newobjs + list
        del self.imagenumber
        return newobjs

    def handles(self, editor, view):
        h = DuplicatorManager.handles(self, editor, view)
        try:
            self.readvalues()
            if not self.offset:
                return h
        except:
            return h
        try:
            count = int(self.dup["count"])
        except:
            count = 1
        for i in range(1, count+1):
            h.append(DupOffsetHandle(self.origin + self.offset*i, self.dup, self.offset, i))
        return h


class OriginDuplicator(DuplicatorManager):
    "Origin for centering of groups"

    Icon = (ico_dict['ico_mapdups'], 0)

    def buildimages(self, singleimage=None):
        return []


class CenterDupHandle(maphandles.IconHandle):

    #
    # Handle at the center of Duplicators.
    #

    def drag(self, v1, v2, flags, view):
        old, new = maphandles.IconHandle.drag(self, v1, v2, flags, view)
        if new is not None and len(new) and (flags&MB_DRAGGING) and self.centerof["out"]:
            #
            # The red image includes the siblings if needed.
            #
            group = quarkx.newobj("redimage:g")
            for obj in self.centerof.parent.subitems:
                if obj in old:
                    obj = new[old.index(obj)]
                else:
                    obj = obj.copy()
                group.appenditem(obj)
            new = [group]
        return old, new



class DupOffsetHandle(maphandles.CenterHandle):

    #
    # Blue handle to set the "offset" of Duplicators.
    #

    def __init__(self, pos, dup, dupoffset, divisor):
        maphandles.CenterHandle.__init__(self, pos, dup, MapColor("Duplicator"))
        self.divisor = divisor
        self.dupoffset = dupoffset

    def drag(self, v1, v2, flags, view):
        import qhandles
        delta = v2-v1
        if flags&MB_CTRL:
            delta = qhandles.aligntogrid(self.pos + delta, 1) - self.pos
        else:
            delta = qhandles.aligntogrid(delta, 0)
        if delta or (flags&MB_REDIMAGE):
            new = self.centerof.copy()
            new["offset"] = str(self.dupoffset + delta/self.divisor)
            if (flags&MB_DRAGGING) and self.centerof["out"]:
                #
                # The red image includes the siblings if needed.
                #
                group = quarkx.newobj("redimage:g")
                for obj in self.centerof.parent.subitems:
                    if obj is self.centerof:
                        obj = new
                    else:
                        obj = obj.copy()
                    group.appenditem(obj)
                new = [group]
            else:
                new = [new]
        else:
            new = None
        return [self.centerof], new

class DupTemplate(StandardDuplicator):
    "Brush template"

    Icon = (ico_objects, 27)
    BuildItem = None

    def applylinear(self, matrix, direct=0):
        szmangle = self.dup["mangle"]
        angles = quarkx.vect(szmangle)
        pitch = -angles.x*deg2rad
        yaw = angles.y*deg2rad
        roll = angles.z*deg2rad

        mat = matrix_rot_z(yaw)*matrix_rot_y(pitch)*matrix_rot_x(roll)
        linear = matrix*mat
        cols = linear.cols
        #
        # get scale
        #
        scale=tuple(map(lambda v:abs(v), cols))
        cols = tuple(map(lambda v:v.normalized, cols))
        #
        # get rotations, cols[0] is 'rotated X axis, compute the others
        #
        axes = quarkx.matrix('1 0 0 0 1 0 0 0 1').cols
        yrot = cols[2]^cols[0]
        zrot = cols[0]^yrot
        pitch = math.asin(cols[0]*axes[2])
        if abs(pitch)<89.99:
            p = projectpointtoplane(cols[0],axes[2],
              quarkx.vect(0,0,0), axes[2]).normalized
            yaw = math.atan2(p.y, p.x)
        else:
            yaw = 0
        y2 = matrix_rot_y(-pitch)*matrix_rot_z(-yaw)*yrot
        roll = math.atan2(y2*axes[2], y2*axes[1])
        self.dup["mangle"] = str(-pitch/deg2rad) + " " + str(yaw/deg2rad) + " " + str(roll/deg2rad)

        originalscale = quarkx.vect("1 1 1")
        if self.dup["scale"] is not None:
            try:
                originalscale = quarkx.vect(self.dup["scale"])
            except:
                simplescale = float(self.dup["scale"])
                originalscale = quarkx.vect(simplescale, simplescale, simplescale)

        self.dup["scale"] = str(originalscale.x*scale[0]) + " " + str(originalscale.y*scale[1]) + " " + str(originalscale.z*scale[2])

    def buildimages(self, singleimage=None):
        def finditem(self):
            editor = None
            forms = quarkx.forms(2)
            for form in forms:
                if (form is not None) and (form.info is not None):
                    Root = None
                    try:
                        Root = form.info.Root
                    except:
                        pass
                    if(Root is not None and Root.shortname.lower() == "worldspawn"):
                        editor = form.info
                        break
                    
            if editor is None:
                return

            worldspawn = editor.Root

            founditem = None

            for key in worldspawn.dictspec.keys():
                p = key.find("TemplateFile")
                if not (p == -1):
                    mapfullname = worldspawn[key]
                    try:
                        m = quarkx.openfileobj(mapfullname)
                    except:
                        quarkx.msgbox("Unable to load '" + mapfullname + "'.", MT_ERROR, MB_OK)
                        return None

                    TemplateWorldspawnFound = None
                    for TemplateWorldspawn in m.subitems:
                        if TemplateWorldspawn.shortname == "worldspawn":
                            TemplateWorldspawnFound = TemplateWorldspawn
                            break

                    if TemplateWorldspawnFound is None:
                        continue

                    for newitem in TemplateWorldspawnFound.subitems:
                        if (newitem.shortname == self.dup.shortname):
                            founditem = newitem.copy()
                            break
                    del m
                    if founditem is not None:
                        return founditem

            # Find next available TemplateFile* key
            i = 0
            while 1:
                NewName = "TemplateFile" + str(i)
                if worldspawn[NewName] is None:
                    break;
                i = i + 1

            worldspawn[NewName] = self.dup["templatefilename"]
            return finditem(self)

        if (singleimage is not None and not(singleimage==0)):
            return []

        if self.BuildItem is None:
            self.BuildItem = finditem(self)

        item = self.BuildItem
        if (item is None):
            return []

        subitems = item.findallsubitems("", ":e")
        
        correctlist = []
        for subitem in subitems:
            if subitem["mangle"] is not None:
                correctlist = correctlist + [subitem]
                subitem["prev_mangle"] = subitem["mangle"]

        origin = self.dup.origin
        if origin is None:
            origin = quarkx.vect(0,0,0)


        szmangle = self.dup["mangle"]
        angles = quarkx.vect(szmangle)
        pitch = -angles.x*deg2rad
        yaw = angles.y*deg2rad
        roll = angles.z*deg2rad

        mat = matrix_rot_z(yaw)*matrix_rot_y(pitch)*matrix_rot_x(roll)

        translate = origin;
        if item["usercenter"]:
            translate = translate - quarkx.vect(item["usercenter"])

        scale = quarkx.vect("1 1 1")
        if self.dup["scale"] is not None:
            try:
                scale = quarkx.vect(self.dup["scale"])
            except:
                simplescale = float(self.dup["scale"])
                scale = quarkx.vect(simplescale, simplescale, simplescale)

        cols = mat.cols
        mat = quarkx.matrix(cols[0] * scale.x, cols[1] * scale.y, cols[2] * scale.z)
        item.translate(translate)
        item.linear(origin, mat)

        for correctitem in correctlist:
            szmangle = correctitem["prev_mangle"]
            angles = quarkx.vect(szmangle)
            pitch = -angles.x*deg2rad
            yaw = angles.y*deg2rad
            roll = angles.z*deg2rad

            ItemMat = matrix_rot_z(yaw)*matrix_rot_y(pitch)*matrix_rot_x(roll)
            linear = mat*ItemMat
            cols = linear.cols
            #
            # get scale
            #
            scale=tuple(map(lambda v:abs(v), cols))
            cols = tuple(map(lambda v:v.normalized, cols))
            #
            # get rotations, cols[0] is 'rotated X axis, compute the others
            #
            axes = quarkx.matrix('1 0 0 0 1 0 0 0 1').cols
            yrot = cols[2]^cols[0]
            zrot = cols[0]^yrot
            pitch = math.asin(cols[0]*axes[2])
            if abs(pitch)<89.99:
                p = projectpointtoplane(cols[0],axes[2],
                  quarkx.vect(0,0,0), axes[2]).normalized
                yaw = math.atan2(p.y, p.x)
            else:
                yaw = 0
            y2 = matrix_rot_y(-pitch)*matrix_rot_z(-yaw)*yrot
            roll = math.atan2(y2*axes[2], y2*axes[1])
            correctitem["mangle"] = str(-pitch/deg2rad) + " " + str(yaw/deg2rad) + " " + str(roll/deg2rad)
            correctitem["prev_mangle"] = ""

        #ArgReplacer function

        def filterspecs(self, specs):
            "Removes MACRO and ORIGIN if they exists in the dictspec.keys() array"
            replacerspecs = []
            for i in specs:
               if (not ((i == "macro") or (i == "origin") or (i == "mangle"))):
                  replacerspecs.append(i)
            return replacerspecs

        def searchandreplace(self, item, replacerspecs):
            for key in item.dictspec.keys():
                szValue = item[key]
                nReplaceStart = -1
                try:
                    nReplaceStart = szValue.find("%")
                except:
                    pass

                if nReplaceStart < 0 or nReplaceStart == (len(szValue)-1):
                    continue

                nReplaceEnd = szValue[nReplaceStart+1:].find("%")

                if nReplaceEnd < 0:
                    continue

                nReplaceEnd = nReplaceEnd + nReplaceStart+1

                szReplaceStr = szValue[nReplaceStart+1:nReplaceEnd]

                nDefaultStart = szReplaceStr.find("[")
                if nDefaultStart < 0 :
                    nDefaultStart = len(szReplaceStr)

                #Replace from specs
                bWasReplaced = 0
                for ReplaceSpec in replacerspecs:
                    if ReplaceSpec == szReplaceStr[:nDefaultStart]:
                        szValue = szValue[:nReplaceStart] + self.dup.dictspec[ReplaceSpec] + szValue[nReplaceEnd+1:]
                        item[key] = szValue
                        bWasReplaced = 1
                        break

                if (bWasReplaced == 1):
                    continue;

                #Set default
                if nDefaultStart >= (len(szReplaceStr)-1):
                    continue;

                nDefaultEnd = szReplaceStr[nDefaultStart+1:].find("]")
                if nDefaultEnd < 0:
                    continue

                nDefaultEnd = nDefaultEnd + nDefaultStart+1
                szValue = szValue[:nReplaceStart] + szReplaceStr[nDefaultStart+1 : nDefaultEnd] + szValue[nReplaceEnd+1:]
                item[key] = szValue

        subitems = item.findallsubitems("", ":e")
        subitems = subitems + item.findallsubitems("", ":b")
        subitems = subitems + item.findallsubitems("", ":d")
        subitems = subitems + item.findallsubitems("", ":b2")
        subitems = subitems + item.findallsubitems("", ":p")
        subitems = subitems + item.findallsubitems("", ":f")

        replacerspecs = filterspecs(self, self.dup.dictspec.keys())

        for subitem in subitems:
            searchandreplace(self, subitem, replacerspecs)

        return [item]

def DupManager(dup):

    #
    # Builds a Duplicator Manager object for the duplicator "dup".
    #

    s = dup["macro"]
    try:
        cls = DupCodes[s]
    except KeyError:
        cls = DuplicatorManager   # abstract base class
    #
    # Build and initialize the new instance.
    #
    mgr = cls()
    mgr.dup = dup
    return mgr


DupCodes = {"dup origin" : OriginDuplicator,
            "Template" : DupTemplate
             }    # see mapdups.py

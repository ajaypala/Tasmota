# zigbee zcl_attributes class
#
# f = open("zcl_attribute.c","w") solidify.dump(zcl_attribute,true,f) solidify.dump(zcl_attribute_list,true,f) f.close()
#  

class zcl_attribute_ntv end
class zcl_attribute_list_ntv end

class zcl_attribute : zcl_attribute_ntv

  def init(ptr)
    super(self).init(ptr)   # call super constructor
    if ptr == nil           # if we allocate ourseleves, initialize the structure with `_init()`
      self._init()
    end
  end

  def deinit()
    if !self.ismapped()     # if we allocated the structure, deallocated all sub-structures first
      self._deinit()
    end
  end

  # virtual accessor overloading some attributes
  def member(k)
    if k == "cluster"
      var v = self._cluster
      return v != 0xFFFF ? v : nil
    elif k == "attr_id"
      var v = self._attr_id
      return ((v != 0xFFFF) && !self._iscmd) ? v : nil
    elif k == "cmd"
      var v = self._cmd
      return ((v != 0xFF) && self._iscmd) ? v : nil
    elif k == "direction"
      var v = self._direction
      return ((v != 0xFF) && self._iscmd) ? (v & 0x01) : nil
    elif k == "val"
      var v = self._get_val()
      if isinstance(v, bytes)
        v = v.tohex()
      end
      return v
    elif k == "key"
      return self._get_key()
    else
      return super(self).member(k)
    end
  end

  def setmember(k, v)
    if k == "cluster"
      if v == nil
        self._cluster = 0xFFFF
      else
        self._cluster = v
      end
    elif k == "attr_id"
      if v == nil
        self._attr_id = 0xFFFF
      else
        self._attr_id = v
        self._iscmd = 0
      end
    elif k == "cmd"
      if v == nil
        self._cmd = 0xFF
      else
        self._cmd = v
        self._iscmd = 1
        if self._direction == 0xFF    # default direction
          self._direction = 0
        end
      end
    elif k == "direction"
      if v == nil
        self._direction = 0xFF
      else
        self._direction = v ? 0x01 : 0x00
        self._iscmd = 1
      end
    elif k == "val"
      self._set_val(v)
    elif k == "key"
      self._set_key(v)
    else
      super(self).setmember(k, v)
    end
  end
  
  # tomap() extended
  def tomap()
    var m = super(self).tomap()
    m['cluster'] = self.cluster
    m['attr_id'] = self.attr_id
    m['cmd'] = self.cmd
    m['direction'] = self.direction
    m['key'] = self.key
    m['val'] = self.val
    return m
  end

  def key_tostring()
    import string
    var s = "<undefined>"

    var key = self.key
    if key != nil
      s = key
      if self.key_suffix > 1
        s += str(self.key_suffix)
      end
    elif (self.cluster != nil) && (self.attr_id != nil)
      s = string.format("%04X/%04X", self.cluster, self.attr_id)
      if self.key_suffix > 1
        s += "+" + str(self.key_suffix)
      end
    elif (self.cluster != nil) && (self.cmd != nil) && (self.direction != nil)
      s = string.format("%04X%s%02X", self.cluster, self.direction ? "<" : "!" ,self.cmd)
      if self.key_suffix > 1
        s += "+" + str(self.key_suffix)
      end
    end
    return s
  end

  # export value so that it can be serialized by json
  def tostring()
    import introspect
    import json
    import string

    var s = json.dump(self.key_tostring())
    s += ":"
    if introspect.get(self.val, "tojson") != nil
      s += self.val.tojson()
    else
      s += json.dump(self.val)
    end

    if (self.cluster != nil) && (self.attr_id != nil) && (self.key != nil)
      # we have an alias
      var key_alias = string.format("(%s)", self.key_tostring())
      s += string.format(',%s:"%04X/%04X"', json.dump(key_alias), self.cluster, self.attr_id)
    end

    return s
  end

end

class zcl_attribute_list : zcl_attribute_list_ntv
  var shortaddr
  # in the bytes object we have:
  #  groupaddr
  #  src_ep
  #  lqi

  def init(ptr)
    super(self).init(ptr)   # call super constructor
    if ptr == nil           # if we allocate ourseleves, initialize the structure with `_init()`
      self._init()
    end
  end

  def deinit()
    if !self.ismapped()     # if we allocated the structure, deallocated all sub-structures first
      self._deinit()
    end
  end

  def member(k)
    if k == "groupaddr"
      var v = self._groupaddr
      return v != 0xFFFF ? v : nil
    elif k == "src_ep"
      var v = self._src_ep
      return v != 0xFF ? v : nil
    elif k == "lqi"
      var v = self._lqi
      return v != 0xFF ? v : nil
    else
      return super(self).member(k)
    end
  end
  
  def setmember(k, v)
    if k == "groupaddr"
      self._groupaddr = (v != nil) ? v : 0xFFFF
    elif k == "src_ep"
      self._src_ep = (v != nil) ? v : 0xFF
    elif k == "lqi"
      self._lqi = (v != nil) ? v : 0xFF
    else
      super(self).setmember(k, v)
    end
  end

  def tostring()
    import string
    import json

    var items = []
    # {"Device":"0x246D","Name":"Plug","EnergyTotal":"0x000000000000","Endpoint":1,"LinkQuality":229}

    # shortaddr
    if self.shortaddr != nil
      items.push(string.format('"Device":"0x%04X"', self.shortaddr))
    end
    # groupaddr
    if self.groupaddr != nil
      items.push(string.format('"Group":"0x%04X"', self.groupaddr))
    end

    # attributes
    var idx = 0
    var attr_size = self.size()
    while idx < attr_size
    # for e: self.attr_list
      items.push(self[idx].tostring())
      idx += 1
    end

    # Endpoint
    if self.src_ep != nil
      items.push(string.format('"Endpoint":%i', self.src_ep))
    end

    # LQI
    if self.lqi != nil
      items.push(string.format('"LinkQuality":%i', self.lqi))
    end

    var s = "{" + items.concat(",") + "}"
    return s

    # return string.format("shortaddr:0x%04X groupaddr:0x%04X %s", self.shortaddr, self.groupaddr, str(self.attr_list))
  end
end

class zcl_attributes
  var shortaddr
  var groupaddr
  var lqi
  var src_ep
  var attr_list

  def init(shortaddr, groupaddr, lqi, src_ep, attr_list)
    self.shortaddr = shortaddr
    self.groupaddr = groupaddr
    self.lqi = lqi
    self.src_ep = src_ep
    if isinstance(self.attr_list, list)
      self.attr_list = attr_list
    else
      self.attr_list = []
    end
  end

  def push(attr)
    self.attr_list.push(attr)
  end

  def tostring()
    import string
    import json

    var items = []
    # {"Device":"0x246D","Name":"Plug","EnergyTotal":"0x000000000000","Endpoint":1,"LinkQuality":229}

    # shortaddr
    if self.shortaddr != nil
      items.push(string.format('"Device":"0x%04X"', self.shortaddr))
    end
    # groupaddr
    if self.shortaddr != nil
      items.push(string.format('"Group":"0x%04X"', self.groupaddr))
    end

    # attributes
    for e: self.attr_list
      items.push(e.tostring())
    end

    # Endpoint
    if self.src_ep != nil
      items.push(string.format('"Endpoint":%i', self.src_ep))
    end

    # Endpoint
    if self.lqi != nil
      items.push(string.format('"LinkQuality":%i', self.lqi))
    end

    var s = "{" + items.concat(",") + "}"
    return s

    # return string.format("shortaddr:0x%04X groupaddr:0x%04X %s", self.shortaddr, self.groupaddr, str(self.attr_list))
  end

end

#-
# Unit tests

# setup for standalone
# zigbee = module("zigbee")
# zigbee.zcl_attribute = zcl_attribute
# zigbee.zcl_attributes = zcl_attributes


#  def init(cluster, attr_id, key, key_suffix, val, multiplier)
import zigbee
l = zigbee.zcl_attribute_list()
assert(l.tostring() == "{}")

l.shortaddr = 0x1234
l.groupaddr = 0x9876
l.src_ep = 1
l.lqi = 99
assert(l.tostring() == '{"Device":"0x1234","Group":"0x9876","Endpoint":1,"LinkQuality":99}')

a1 = l.new_tail()
a1.cluster = 0x100
a1.attr_id = 0x200
a1.val = 10
assert(a1.tostring() == '"0100/0200":10')

a10 = l.new_tail()
a10.cluster = 0x100
a10.attr_id = 0x200
a10.key = "Name"
a10.val = 10
assert(a10.tostring() == '"Name":10,"Name(0100/0200)":null')

a2 = l.new_tail()
a2.cluster = 0x101
a2.attr_id = 0x201
a2.key_suffix = 2
a2.val = 3.5
assert(a2.tostring() == '"0101/0201+2":3.5')

a3 = l.new_tail()
a3.key = "foobar"
a3.key_suffix = 3
a3.val = "baz"
assert(a3.tostring() == '"foobar3":"baz"')

a4 = l.new_tail()
a4.key = "Power"
a4.val = true
assert(a4.tostring() == '"Power":true')

a5 = l.new_head()
a5.key = "Unknown"
assert(a5.tostring() == '"Unknown":null')

assert(l.tostring() == '{"Device":"0x1234","Group":"0x9876","Unknown":null,"0100/0200":10,"Name":10,"Name(0100/0200)":null,"0101/0201+2":3.5,"foobar3":"baz","Power":true,"Endpoint":1,"LinkQuality":99}')

b1 = zigbee.zcl_attribute()
b1.cluster = 0x0600
b1.cmd = 0x01
b1.direction = 0
b1.val = bytes('01')
assert(b1.tostring() == '"0600!01":"01"')

-#

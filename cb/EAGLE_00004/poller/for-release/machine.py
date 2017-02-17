# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4
from generator.actions import Actions
from random import randint,choice
from socket import htonl
import ctypes

class eagle_00004(Actions):
    def init(self):
        self.registers = [0,0,0,0]
        self.stack = []
        for x in range(256):
            self.stack.append(0)
        self.memory = []
        for x in range(256):
            self.memory.append(0)
        self.esp = 0

        self.OP_TYPE_REG = 0
        self.OP_TYPE_MEM = 1
        
        self.output = ""
    
    def random_string(self, size):
        chars = string.letters + string.digits
        return ''.join(choice(chars) for _ in range(size))

    def Password(self): 
        self.write("aPenFullOfSheep:)\n")

    def Push(self, value):
        if self.esp == 255:
                return

        self.write("push {}\n".format(value))
        self.esp += 1
        self.stack[self.esp] = value

    def Pop(self, optype, location):
        if self.esp == 0:
                return

        if optype == self.OP_TYPE_REG:
            self.write("pop r{}\n".format(location))
            self.registers[location] = self.stack[self.esp]
        else:
            self.write("pop m{}\n".format(location))
            self.memory[location] = self.stack[self.esp]

        self.esp -= 1

    def Out(self, optype, location):
        if optype == self.OP_TYPE_REG:
            self.write("out r{}\n".format(location))
            self.output += "OUT: {:#010x}\n".format(self.registers[location] & 0xffffffff)
        else:
            self.write("out m{}\n".format(location))
            self.output += "OUT: {:#010x}\n".format(self.memory[location] & 0xffffffff)

    def Add(self, optype1, location1, optype2, location2):
        instr = "add "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
        else:
            instr += "m"
        instr += "{},".format(location1)

        if optype2 == self.OP_TYPE_REG:
            instr += "r"
            value = self.registers[location2]
        else:
            instr += "m"
            value = self.memory[location2]
        instr += "{}\n".format(location2)

        self.write(instr)

        if optype1 == self.OP_TYPE_REG:
            self.registers[location1] += value
        else:
            self.memory[location1] += value

    def Sub(self, optype1, location1, optype2, location2):
        instr = "sub "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
        else:
            instr += "m"
        instr += "{},".format(location1)

        if optype2 == self.OP_TYPE_REG:
            instr += "r"
            value = self.registers[location2]
        else:
            instr += "m"
            value = self.memory[location2]
        instr += "{}\n".format(location2)

        self.write(instr)

        if optype1 == self.OP_TYPE_REG:
            self.registers[location1] -= value
        else:
            self.memory[location1] -= value

    def Mul(self, optype1, location1, optype2, location2):
        instr = "mul "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
        else:
            instr += "m"
        instr += "{},".format(location1)

        if optype2 == self.OP_TYPE_REG:
            instr += "r"
            value = self.registers[location2]
        else:
            instr += "m"
            value = self.memory[location2]
        instr += "{}\n".format(location2)

        self.write(instr)

        if optype1 == self.OP_TYPE_REG:
            self.registers[location1] *= value
        else:
            self.memory[location1] *= value

    def Div(self, optype1, location1, optype2, location2):
        instr = "div "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
        else:
            instr += "m"
        instr += "{},".format(location1)

        if optype2 == self.OP_TYPE_REG:
            instr += "r"
            value = self.registers[location2]
        else:
            instr += "m"
            value = self.memory[location2]
        instr += "{}\n".format(location2)

        self.write(instr)

        if optype1 == self.OP_TYPE_REG:
            self.registers[location1] = int(float(self.registers[location1]) / value)
        else:
            self.memory[location1] = int(float(self.memory[location1]) / value)

    def Mod(self, optype1, location1, optype2, location2):
        instr = "mod "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
        else:
            instr += "m"
        instr += "{},".format(location1)

        if optype2 == self.OP_TYPE_REG:
            instr += "r"
            value = self.registers[location2]
        else:
            instr += "m"
            value = self.memory[location2]
        instr += "{}\n".format(location2)

        self.write(instr)

        if optype1 == self.OP_TYPE_REG:
            self.registers[location1] = self.registers[location1] % value
        else:
            self.memory[location1] = self.memory[location1] % value

    def Shl(self, optype1, location1, location2):
        instr = "shl "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
            self.registers[location1] = (self.registers[location1] << location2) & 0xffffffff
        else:
            instr += "m"
            self.memory[location1] = (self.memory[location1] << location2) & 0xffffffff
        instr += "{},{}\n".format(location1, location2)
        self.write(instr)

    def Shr(self, optype1, location1, location2):
        instr = "shr "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
            tmp = ctypes.c_int32(self.registers[location1])
            tmp.value >>= location2
            self.registers[location1] = tmp.value
        else:
            instr += "m"
            tmp = ctypes.c_int32(self.memory[location1])
            tmp.value >>= location2
            self.memory[location1] = tmp.value
        instr += "{},{}\n".format(location1, location2)
        self.write(instr)

    def Exc(self, optype1, location1, optype2, location2):
        instr = "exc "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
            temp = self.registers[location1]
        else:
            instr += "m"
            temp = self.memory[location1]
        instr += "{},".format(location1)

        if optype2 == self.OP_TYPE_REG:
            instr += "r"
            if optype1 == self.OP_TYPE_REG:
                self.registers[location1] = self.registers[location2]
                self.registers[location2] = temp
            else:
                self.memory[location1] = self.registers[location2]
                self.registers[location2] = temp
        else:
            instr += "m"
            if optype1 == self.OP_TYPE_REG:
                self.registers[location1] = self.memory[location2]
                self.memory[location2] = temp
            else:
                self.memory[location1] = self.memory[location2]
                self.memory[location2] = temp
        instr += "{}\n".format(location2)
        self.write(instr)

    def myhtonl(self, i):
        return ctypes.c_int32(htonl(ctypes.c_uint32(i).value)).value
        
    def Swp(self, optype1, location1):
        instr = "swp "
        if optype1 == self.OP_TYPE_REG:
            instr += "r"
            self.registers[location1] = self.myhtonl(self.registers[location1])
        else:
            instr += "m"
            self.memory[location1] = self.myhtonl(self.memory[location1])
        instr += "{}\n".format(location1)
        self.write(instr)

    def RndAdd(self):
        # put something interesting in the src and dst
        val1 = randint(-2147483648, 2147483647)
        val2 = randint(-2147483648, 2147483647)
        optype1 = randint(0,1)
        optype2 = randint(0,1)
        if (optype1 == 0):
            location1 = randint(0,3)
        else:
            location1 = randint(0,255)
        if (optype2 == 0):
            location2 = randint(0,3)
        else:
            location2 = randint(0,255)

        self.Push(val1)
        self.Pop(optype1, location1)
        self.Push(val2)
        self.Pop(optype2, location2)

        if randint(0,1):
                self.Exc(optype1, location1, optype2, location2)

        if randint(0,1):
                self.Swp(optype1, location1)

        if randint(0,1):
                self.Swp(optype2, location2)
            
        if randint(0,1):
                self.Shl(optype1, location1, randint(1,31))
            
        if randint(0,1):
                self.Shr(optype2, location2, randint(1,31))
            
        self.Add(optype1, location1, optype2, location2)
        self.Out(optype1, location1)
        self.Out(optype2, location2)

    def RndSub(self):
        # put something interesting in the src and dst
        val1 = randint(-2147483648, 2147483647)
        val2 = randint(-2147483648, 2147483647)
        optype1 = randint(0,1)
        optype2 = randint(0,1)
        if (optype1 == 0):
            location1 = randint(0,3)
        else:
            location1 = randint(0,255)
        if (optype2 == 0):
            location2 = randint(0,3)
        else:
            location2 = randint(0,255)

        self.Push(val1)
        self.Pop(optype1, location1)
        self.Push(val2)
        self.Pop(optype2, location2)

        if randint(0,1):
                self.Exc(optype1, location1, optype2, location2)

        if randint(0,1):
                self.Swp(optype1, location1)

        if randint(0,1):
                self.Swp(optype2, location2)
            
        if randint(0,1):
                self.Shl(optype1, location1, randint(1,31))
            
        if randint(0,1):
                self.Shr(optype2, location2, randint(1,31))
            
        self.Sub(optype1, location1, optype2, location2)
        self.Out(optype1, location1)
        self.Out(optype2, location2)

    def RndMul(self):
        # put something interesting in the src and dst
        val1 = randint(-2147483648, 2147483647)
        val2 = randint(-2147483648, 2147483647)
        optype1 = randint(0,1)
        optype2 = randint(0,1)
        if (optype1 == 0):
            location1 = randint(0,3)
        else:
            location1 = randint(0,255)
        if (optype2 == 0):
            location2 = randint(0,3)
        else:
            location2 = randint(0,255)

        self.Push(val1)
        self.Pop(optype1, location1)
        self.Push(val2)
        self.Pop(optype2, location2)

        if randint(0,1):
                self.Exc(optype1, location1, optype2, location2)

        if randint(0,1):
                self.Swp(optype1, location1)

        if randint(0,1):
                self.Swp(optype2, location2)
            
        if randint(0,1):
                self.Shl(optype1, location1, randint(1,31))
            
        if randint(0,1):
                self.Shr(optype2, location2, randint(1,31))
            
        self.Mul(optype1, location1, optype2, location2)
        self.Out(optype1, location1)
        self.Out(optype2, location2)

    def RndDiv(self):
        # put something interesting in the src and dst
        val1 = randint(-2147483648, 2147483647)
        val2 = randint(-2147483648, 2147483647)
        while val2 == 0:
            val2 = randint(-2147483648, 2147483647)
        optype1 = randint(0,1)
        optype2 = randint(0,1)
        if (optype1 == 0):
            location1 = randint(0,3)
        else:
            location1 = randint(0,255)
        if (optype2 == 0):
            location2 = randint(0,3)
        else:
            location2 = randint(0,255)

        self.Push(val1)
        self.Pop(optype1, location1)
        self.Push(val2)
        self.Pop(optype2, location2)

        self.Div(optype1, location1, optype2, location2)
        self.Out(optype1, location1)
        self.Out(optype2, location2)

    def RndMod(self):
        # put something interesting in the src and dst
        val1 = randint(1, 2147483647)
        val2 = randint(1, 2147483647)
        while val2 == 0:
            val2 = randint(-2147483648, 2147483647)
        optype1 = randint(0,1)
        optype2 = randint(0,1)
        if (optype1 == 0):
            location1 = randint(0,3)
        else:
            location1 = randint(0,255)
        if (optype2 == 0):
            location2 = randint(0,3)
        else:
            location2 = randint(0,255)

        self.Push(val1)
        self.Pop(optype1, location1)
        self.Push(val2)
        self.Pop(optype2, location2)

        self.Mod(optype1, location1, optype2, location2)
        self.Out(optype1, location1)
        self.Out(optype2, location2)

    def start(self):
        self.init()
        self.Password()

        for x in range(20):
            rnd = randint(0,4)
            if rnd == 0:
                self.RndAdd()
            elif rnd == 1:
                self.RndSub()
            elif rnd == 2:
                self.RndMul()
            elif rnd == 3:
                self.RndDiv()
            elif rnd == 4:
                self.RndMod()

        self.write("END\n")

        self.read(length=len(self.output), expect=self.output)
        self.read(delim="\n", expect="COMPLETE\n")


    def end(self):
	pass


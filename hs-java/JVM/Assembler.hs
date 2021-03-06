{-# LANGUAGE TypeFamilies, FlexibleInstances,
   FlexibleContexts, UndecidableInstances, RecordWildCards, OverloadedStrings,
   TypeSynonymInstances, MultiParamTypeClasses #-}
-- | This module declares data type for JVM instructions, and BinaryState
-- instances to read/write them.
module JVM.Assembler
  (Instruction (..),
   ArrayType (..),
   IMM (..),
   CMP (..),
   atype2byte,
   readInstructions)
  where

import Control.Monad
import Data.Ix (inRange)
import Data.Int
import Data.Word
import Data.Binary
import Data.Binary.Get
import Data.Binary.Put
import qualified Data.ByteString.Lazy as B

-- | Immediate constant. Corresponding value will be added to base opcode.
data IMM =
    I0     -- ^ 0
  | I1     -- ^ 1
  | I2     -- ^ 2
  | I3     -- ^ 3
  deriving (Eq, Ord, Enum, Show)

-- | Comparation operation type. Not all CMP instructions support all operations.
data CMP =
    C_EQ
  | C_NE
  | C_LT
  | C_GE
  | C_GT
  | C_LE
  deriving (Eq, Ord, Enum, Show)

-- | Read sequence of instructions (to end of stream)
readInstructions :: (Integral a, Integral b) => a -> b -> Get [Instruction]
readInstructions offset length
  | length == 0 = return []
  | otherwise = do
      x <- get
      read <- bytesRead
      next <- readInstructions read (length - (fromIntegral read) + (fromIntegral offset))
      return (x : next)

-- | JVM instruction set. For comments, see JVM specification.
data Instruction =
    NOP            -- ^ 0
  | ACONST_NULL    -- ^ 1
  | ICONST_M1      -- ^ 2
  | ICONST_0       -- ^ 3
  | ICONST_1       -- ^ 4
  | ICONST_2       -- ^ 5
  | ICONST_3       -- ^ 6
  | ICONST_4       -- ^ 7
  | ICONST_5       -- ^ 8
  | LCONST_0       -- ^ 9
  | LCONST_1       -- ^ 10
  | FCONST_0       -- ^ 11
  | FCONST_1       -- ^ 12
  | FCONST_2       -- ^ 13
  | DCONST_0       -- ^ 14
  | DCONST_1       -- ^ 15
  | BIPUSH Word8   -- ^ 16
  | SIPUSH Word16  -- ^ 17
  | LDC1 Word8     -- ^ 18
  | LDC2 Word16    -- ^ 19
  | LDC2W Word16   -- ^ 20
  | ILOAD Word8    -- ^ 21
  | LLOAD Word8    -- ^ 22
  | FLOAD Word8    -- ^ 23
  | DLOAD Word8    -- ^ 24
  | ALOAD Word8    -- ^ 25
  | ILOAD_ IMM     -- ^ 26, 27, 28, 29
  | LLOAD_ IMM     -- ^ 30, 31, 32, 33
  | FLOAD_ IMM     -- ^ 34, 35, 36, 37
  | DLOAD_ IMM     -- ^ 38, 39, 40, 41
  | ALOAD_ IMM     -- ^ 42, 43, 44, 45
  | IALOAD         -- ^ 46
  | LALOAD         -- ^ 47
  | FALOAD         -- ^ 48
  | DALOAD         -- ^ 49
  | AALOAD         -- ^ 50
  | BALOAD         -- ^ 51
  | CALOAD         -- ^ 52
  | SALOAD         -- ^ 53
  | ISTORE Word8   -- ^ 54
  | LSTORE Word8   -- ^ 55
  | FSTORE Word8   -- ^ 56
  | DSTORE Word8   -- ^ 57
  | ASTORE Word8   -- ^ 58
  | ISTORE_ IMM    -- ^ 59, 60, 61, 62
  | LSTORE_ IMM    -- ^ 63, 64, 65, 66
  | FSTORE_ IMM    -- ^ 67, 68, 69, 70
  | DSTORE_ IMM    -- ^ 71, 72, 73, 74
  | ASTORE_ IMM    -- ^ 75, 76, 77, 78
  | IASTORE        -- ^ 79
  | LASTORE        -- ^ 80
  | FASTORE        -- ^ 81
  | DASTORE        -- ^ 82
  | AASTORE        -- ^ 83
  | BASTORE        -- ^ 84
  | CASTORE        -- ^ 85
  | SASTORE        -- ^ 86
  | POP            -- ^ 87
  | POP2           -- ^ 88
  | DUP            -- ^ 89
  | DUP_X1         -- ^ 90
  | DUP_X2         -- ^ 91
  | DUP2           -- ^ 92
  | DUP2_X1        -- ^ 93
  | DUP2_X2        -- ^ 94
  | SWAP           -- ^ 95
  | IADD           -- ^ 96
  | LADD           -- ^ 97
  | FADD           -- ^ 98
  | DADD           -- ^ 99
  | ISUB           -- ^ 100
  | LSUB           -- ^ 101
  | FSUB           -- ^ 102
  | DSUB           -- ^ 103
  | IMUL           -- ^ 104
  | LMUL           -- ^ 105
  | FMUL           -- ^ 106
  | DMUL           -- ^ 107
  | IDIV           -- ^ 108
  | LDIV           -- ^ 109
  | FDIV           -- ^ 110
  | DDIV           -- ^ 111
  | IREM           -- ^ 112
  | LREM           -- ^ 113
  | FREM           -- ^ 114
  | DREM           -- ^ 115
  | INEG           -- ^ 116
  | LNEG           -- ^ 117
  | FNEG           -- ^ 118
  | DNEG           -- ^ 119
  | ISHL           -- ^ 120
  | LSHL           -- ^ 121
  | ISHR           -- ^ 122
  | LSHR           -- ^ 123
  | IUSHR          -- ^ 124
  | LUSHR          -- ^ 125
  | IAND           -- ^ 126
  | LAND           -- ^ 127
  | IOR            -- ^ 128
  | LOR            -- ^ 129
  | IXOR           -- ^ 130
  | LXOR           -- ^ 131
  | IINC Word8 Word8       -- ^ 132
  | I2L                    -- ^ 133
  | I2F                    -- ^ 134
  | I2D                    -- ^ 135
  | L2I                    -- ^ 136
  | L2F                    -- ^ 137
  | L2D                    -- ^ 138
  | F2I                    -- ^ 139
  | F2L                    -- ^ 140
  | F2D                    -- ^ 141
  | D2I                    -- ^ 142
  | D2L                    -- ^ 143
  | D2F                    -- ^ 144
  | I2B                    -- ^ 145
  | I2C                    -- ^ 146
  | I2S                    -- ^ 147
  | LCMP                   -- ^ 148
  | FCMP CMP               -- ^ 149, 150
  | DCMP CMP               -- ^ 151, 152
  | IF CMP Word16          -- ^ 153, 154, 155, 156, 157, 158
  | IF_ICMP CMP Word16     -- ^ 159, 160, 161, 162, 163, 164
  | IF_ACMP CMP Word16     -- ^ 165, 166
  | GOTO Int16            -- ^ 167
  | JSR Int16             -- ^ 168
  | RET                    -- ^ 169
  | TABLESWITCH Word8 Int32 Int32 Int32 [Int32]     -- ^ 170
  | LOOKUPSWITCH Word8 Int32 Int32 [(Int32, Int32)] -- ^ 171
  | IRETURN                -- ^ 172
  | LRETURN                -- ^ 173
  | FRETURN                -- ^ 174
  | DRETURN                -- ^ 175
  | ARETURN                -- ^ 176
  | RETURN                 -- ^ 177
  | GETSTATIC Word16       -- ^ 178
  | PUTSTATIC Word16       -- ^ 179
  | GETFIELD Word16        -- ^ 180
  | PUTFIELD Word16        -- ^ 181
  | INVOKEVIRTUAL Word16   -- ^ 182
  | INVOKESPECIAL Word16   -- ^ 183
  | INVOKESTATIC Word16    -- ^ 184
  | INVOKEINTERFACE Word16 Word8 -- ^ 185
  | INVOKEDYNAMIC Word16   -- ^ 186
  | NEW Word16             -- ^ 187
  | NEWARRAY Word8         -- ^ 188, see @ArrayType@
  | ANEWARRAY Word16       -- ^ 189
  | ARRAYLENGTH            -- ^ 190
  | ATHROW                 -- ^ 191
  | CHECKCAST Word16       -- ^ 192
  | INSTANCEOF Word16      -- ^ 193
  | MONITORENTER           -- ^ 194
  | MONITOREXIT            -- ^ 195
  | WIDE Word8 Instruction -- ^ 196
  | MULTINANEWARRAY Word16 Word8 -- ^ 197
  | IFNULL Word16          -- ^ 198
  | IFNONNULL Word16       -- ^ 199
  | GOTO_W Int32          -- ^ 200
  | JSR_W Int32           -- ^ 201
  deriving (Eq, Show)

-- | JVM array type (primitive types)
data ArrayType =
    T_BOOLEAN  -- ^ 4
  | T_CHAR     -- ^ 5
  | T_FLOAT    -- ^ 6
  | T_DOUBLE   -- ^ 7
  | T_BYTE     -- ^ 8
  | T_SHORT    -- ^ 9
  | T_INT      -- ^ 10
  | T_LONG     -- ^ 11
  deriving (Eq, Show, Enum)

-- | Parse opcode with immediate constant
imm :: Word8                   -- ^ Base opcode
    -> (IMM -> Instruction)    -- ^ Instruction constructor
    -> Word8                   -- ^ Opcode to parse
    -> Get Instruction
imm base constr x = return $ constr $ toEnum $ fromIntegral (x-base)

-- | Put opcode with immediate constant
putImm :: Word8                -- ^ Base opcode
       -> IMM                  -- ^ Constant to add to opcode
       -> Put
putImm base i = putWord8 $ base + (fromIntegral $ fromEnum i)

atype2byte :: ArrayType -> Word8
atype2byte T_BOOLEAN  = 4
atype2byte T_CHAR     = 5
atype2byte T_FLOAT    = 6
atype2byte T_DOUBLE   = 7
atype2byte T_BYTE     = 8
atype2byte T_SHORT    = 9
atype2byte T_INT      = 10
atype2byte T_LONG     = 11

byte2atype :: Word8 -> Get ArrayType
byte2atype 4  = return T_BOOLEAN
byte2atype 5  = return T_CHAR
byte2atype 6  = return T_FLOAT
byte2atype 7  = return T_DOUBLE
byte2atype 8  = return T_BYTE
byte2atype 9  = return T_SHORT
byte2atype 10 = return T_INT
byte2atype 11 = return T_LONG
byte2atype x  = fail $ "Unknown array type byte: " ++ show x

instance Binary ArrayType where
  get = get >>= byte2atype
  put t = put (atype2byte t)

-- instance BinaryState Integer ArrayType where
--   get = do
--     x <- getByte
--     byte2atype x

--   put t = putByte (atype2byte t)

-- | Put opcode with one argument
put1 ::  (Binary a)
      => Word8                  -- ^ Opcode
      -> a                      -- ^ First argument
      -> Put
put1 code x = do
  put code
  put x

put2 :: (Binary a, Binary b)
     => Word8                   -- ^ Opcode
     -> a                       -- ^ First argument
     -> b                       -- ^ Second argument
     -> Put
put2 code x y = do
  put code
  put x
  put y

instance Binary Instruction where
  put  NOP         = putWord8 0
  put  ACONST_NULL = putWord8 1
  put  ICONST_M1   = putWord8 2
  put  ICONST_0    = putWord8 3
  put  ICONST_1    = putWord8 4
  put  ICONST_2    = putWord8 5
  put  ICONST_3    = putWord8 6
  put  ICONST_4    = putWord8 7
  put  ICONST_5    = putWord8 8
  put  LCONST_0    = putWord8 9
  put  LCONST_1    = putWord8 10
  put  FCONST_0    = putWord8 11
  put  FCONST_1    = putWord8 12
  put  FCONST_2    = putWord8 13
  put  DCONST_0    = putWord8 14
  put  DCONST_1    = putWord8 15
  put (BIPUSH x)   = put1 16 x
  put (SIPUSH x)   = put1 17 x
  put (LDC1 x)     = put1 18 x
  put (LDC2 x)     = put1 19 x
  put (LDC2W x)    = put1 20 x
  put (ILOAD x)    = put1 21 x
  put (LLOAD x)    = put1 22 x
  put (FLOAD x)    = put1 23 x
  put (DLOAD x)    = put1 24 x
  put (ALOAD x)    = put1 25 x
  put (ILOAD_ i)   = putImm 26 i
  put (LLOAD_ i)   = putImm 30 i
  put (FLOAD_ i)   = putImm 34 i
  put (DLOAD_ i)   = putImm 38 i
  put (ALOAD_ i)   = putImm 42 i
  put  IALOAD      = putWord8 46
  put  LALOAD      = putWord8 47
  put  FALOAD      = putWord8 48
  put  DALOAD      = putWord8 49
  put  AALOAD      = putWord8 50
  put  BALOAD      = putWord8 51
  put  CALOAD      = putWord8 52
  put  SALOAD      = putWord8 53
  put (ISTORE x)   = put1  54 x
  put (LSTORE x)   = put1  55 x
  put (FSTORE x)   = put1  56 x
  put (DSTORE x)   = put1  57 x
  put (ASTORE x)   = put1  58 x
  put (ISTORE_ i)  = putImm 59 i
  put (LSTORE_ i)  = putImm 63 i
  put (FSTORE_ i)  = putImm 67 i
  put (DSTORE_ i)  = putImm 71 i
  put (ASTORE_ i)  = putImm 75 i
  put  IASTORE     = putWord8 79
  put  LASTORE     = putWord8 80
  put  FASTORE     = putWord8 81
  put  DASTORE     = putWord8 82
  put  AASTORE     = putWord8 83
  put  BASTORE     = putWord8 84
  put  CASTORE     = putWord8 85
  put  SASTORE     = putWord8 86
  put  POP         = putWord8 87
  put  POP2        = putWord8 88
  put  DUP         = putWord8 89
  put  DUP_X1      = putWord8 90
  put  DUP_X2      = putWord8 91
  put  DUP2        = putWord8 92
  put  DUP2_X1     = putWord8 93
  put  DUP2_X2     = putWord8 94
  put  SWAP        = putWord8 95
  put  IADD        = putWord8 96
  put  LADD        = putWord8 97
  put  FADD        = putWord8 98
  put  DADD        = putWord8 99
  put  ISUB        = putWord8 100
  put  LSUB        = putWord8 101
  put  FSUB        = putWord8 102
  put  DSUB        = putWord8 103
  put  IMUL        = putWord8 104
  put  LMUL        = putWord8 105
  put  FMUL        = putWord8 106
  put  DMUL        = putWord8 107
  put  IDIV        = putWord8 108
  put  LDIV        = putWord8 109
  put  FDIV        = putWord8 110
  put  DDIV        = putWord8 111
  put  IREM        = putWord8 112
  put  LREM        = putWord8 113
  put  FREM        = putWord8 114
  put  DREM        = putWord8 115
  put  INEG        = putWord8 116
  put  LNEG        = putWord8 117
  put  FNEG        = putWord8 118
  put  DNEG        = putWord8 119
  put  ISHL        = putWord8 120
  put  LSHL        = putWord8 121
  put  ISHR        = putWord8 122
  put  LSHR        = putWord8 123
  put  IUSHR       = putWord8 124
  put  LUSHR       = putWord8 125
  put  IAND        = putWord8 126
  put  LAND        = putWord8 127
  put  IOR         = putWord8 128
  put  LOR         = putWord8 129
  put  IXOR        = putWord8 130
  put  LXOR        = putWord8 131
  put (IINC x y)      = put2 132 x y
  put  I2L            = putWord8 133
  put  I2F            = putWord8 134
  put  I2D            = putWord8 135
  put  L2I            = putWord8 136
  put  L2F            = putWord8 137
  put  L2D            = putWord8 138
  put  F2I            = putWord8 139
  put  F2L            = putWord8 140
  put  F2D            = putWord8 141
  put  D2I            = putWord8 142
  put  D2L            = putWord8 143
  put  D2F            = putWord8 144
  put  I2B            = putWord8 145
  put  I2C            = putWord8 146
  put  I2S            = putWord8 147
  put  LCMP           = putWord8 148
  put (FCMP C_LT)     = putWord8 149
  put (FCMP C_GT)     = putWord8 150
  put (FCMP c)        = fail $ "No such instruction: FCMP " ++ show c
  put (DCMP C_LT)     = putWord8 151
  put (DCMP C_GT)     = putWord8 152
  put (DCMP c)        = fail $ "No such instruction: DCMP " ++ show c
  put (IF c x)        = putWord8 (fromIntegral $ 153 + fromEnum c) >> put x
  put (IF_ACMP C_EQ x) = put1 165 x
  put (IF_ACMP C_NE x) = put1 166 x
  put (IF_ACMP c _)   = fail $ "No such instruction: IF_ACMP " ++ show c
  put (IF_ICMP c x)   = putWord8 (fromIntegral $ 159 + fromEnum c) >> put x
  put (GOTO x)        = put1 167 x
  put (JSR x)         = put1 168 x
  put  RET            = putWord8 169
  put (TABLESWITCH offset def low high offs) = do
    putWord8 170
    replicateM_ (fromIntegral offset) (putWord8 0)
    put low
    put high
    forM_ offs put
  put (LOOKUPSWITCH offset def n pairs) = do
    putWord8 171
    replicateM_ (fromIntegral offset) (putWord8 0)
    put def
    put n
    forM_ pairs put
  put  IRETURN        = putWord8 172
  put  LRETURN        = putWord8 173
  put  FRETURN        = putWord8 174
  put  DRETURN        = putWord8 175
  put  ARETURN        = putWord8 176
  put  RETURN         = putWord8 177
  put (GETSTATIC x)   = put1 178 x
  put (PUTSTATIC x)   = put1 179 x
  put (GETFIELD x)    = put1 180 x
  put (PUTFIELD x)    = put1 181 x
  put (INVOKEVIRTUAL x)     = put1 182 x
  put (INVOKESPECIAL x)     = put1 183 x
  put (INVOKESTATIC x)      = put1 184 x
  put (INVOKEINTERFACE x c) = put2 185 x c >> putWord8 0
  put (INVOKEDYNAMIC x) = put1 186 x >> putWord16be 0
  put (NEW x)         = put1 187 x
  put (NEWARRAY x)    = put1 188 x
  put (ANEWARRAY x)   = put1 189 x
  put  ARRAYLENGTH    = putWord8 190
  put  ATHROW         = putWord8 191
  put (CHECKCAST x)   = put1 192 x
  put (INSTANCEOF x)  = put1 193 x
  put  MONITORENTER   = putWord8 194
  put  MONITOREXIT    = putWord8 195
  put (WIDE x inst)   = put2 196 x inst
  put (MULTINANEWARRAY x y) = put2 197 x y
  put (IFNULL x)      = put1 198 x
  put (IFNONNULL x)   = put1 199 x
  put (GOTO_W x)      = put1 200 x
  put (JSR_W x)       = put1 201 x

  get = do
    c <- getWord8
    case c of
      0 -> return NOP
      1 -> return ACONST_NULL
      2 -> return ICONST_M1
      3 -> return ICONST_0
      4 -> return ICONST_1
      5 -> return ICONST_2
      6 -> return ICONST_3
      7 -> return ICONST_4
      8 -> return ICONST_5
      9 -> return LCONST_0
      10 -> return LCONST_1
      11 -> return FCONST_0
      12 -> return FCONST_1
      13 -> return FCONST_2
      14 -> return DCONST_0
      15 -> return DCONST_1
      16 -> BIPUSH <$> get
      17 -> SIPUSH <$> get
      18 -> LDC1 <$> get
      19 -> LDC2 <$> get
      20 -> LDC2W <$> get
      21 -> ILOAD <$> get
      22 -> LLOAD <$> get
      23 -> FLOAD <$> get
      24 -> DLOAD <$> get
      25 -> ALOAD <$> get
      46 -> return IALOAD
      47 -> return LALOAD
      48 -> return FALOAD
      49 -> return DALOAD
      50 -> return AALOAD
      51 -> return BALOAD
      52 -> return CALOAD
      53 -> return SALOAD
      54 -> ISTORE <$> get
      55 -> LSTORE <$> get
      56 -> FSTORE <$> get
      57 -> DSTORE <$> get
      58 -> ASTORE <$> get
      79 -> return IASTORE
      80 -> return LASTORE
      81 -> return FASTORE
      82 -> return DASTORE
      83 -> return AASTORE
      84 -> return BASTORE
      85 -> return CASTORE
      86 -> return SASTORE
      87 -> return POP
      88 -> return POP2
      89 -> return DUP
      90 -> return DUP_X1
      91 -> return DUP_X2
      92 -> return DUP2
      93 -> return DUP2_X1
      94 -> return DUP2_X2
      95 -> return SWAP
      96 -> return IADD
      97 -> return LADD
      98 -> return FADD
      99 -> return DADD
      100 -> return ISUB
      101 -> return LSUB
      102 -> return FSUB
      103 -> return DSUB
      104 -> return IMUL
      105 -> return LMUL
      106 -> return FMUL
      107 -> return DMUL
      108 -> return IDIV
      109 -> return LDIV
      110 -> return FDIV
      111 -> return DDIV
      112 -> return IREM
      113 -> return LREM
      114 -> return FREM
      115 -> return DREM
      116 -> return INEG
      117 -> return LNEG
      118 -> return FNEG
      119 -> return DNEG
      120 -> return ISHL
      121 -> return LSHL
      122 -> return ISHR
      123 -> return LSHR
      124 -> return IUSHR
      125 -> return LUSHR
      126 -> return IAND
      127 -> return LAND
      128 -> return IOR
      129 -> return LOR
      130 -> return IXOR
      131 -> return LXOR
      132 -> IINC <$> get <*> get
      133 -> return I2L
      134 -> return I2F
      135 -> return I2D
      136 -> return L2I
      137 -> return L2F
      138 -> return L2D
      139 -> return F2I
      140 -> return F2L
      141 -> return F2D
      142 -> return D2I
      143 -> return D2L
      144 -> return D2F
      145 -> return I2B
      146 -> return I2C
      147 -> return I2S
      148 -> return LCMP
      149 -> return $ FCMP C_LT
      150 -> return $ FCMP C_GT
      151 -> return $ DCMP C_LT
      152 -> return $ DCMP C_GT
      165 -> IF_ACMP C_EQ <$> get
      166 -> IF_ACMP C_NE <$> get
      167 -> GOTO <$> get
      168 -> JSR <$> get
      169 -> return RET
      170 -> do
        offset <- bytesRead
        let pads = padding offset
        skip pads
        def <- get
        low <- get
        high <- get
        offs <- replicateM (fromIntegral $ high - low + 1) get
        return $ TABLESWITCH (fromIntegral pads) def low high offs
      171 -> do
        offset <- bytesRead
        let pads = padding offset
        skip pads
        def <- get
        n <- get
        pairs <- replicateM (fromIntegral n) get
        return $ LOOKUPSWITCH (fromIntegral pads) def n pairs
      172 -> return IRETURN
      173 -> return LRETURN
      174 -> return FRETURN
      175 -> return DRETURN
      176 -> return ARETURN
      177 -> return RETURN
      178 -> GETSTATIC <$> get
      179 -> PUTSTATIC <$> get
      180 -> GETFIELD <$> get
      181 -> PUTFIELD <$> get
      182 -> INVOKEVIRTUAL <$> get
      183 -> INVOKESPECIAL <$> get
      184 -> INVOKESTATIC <$> get
      185 -> (INVOKEINTERFACE <$> get <*> get) <* skip 1
      186 -> (INVOKEDYNAMIC <$> get) <* skip 2
      187 -> NEW <$> get
      188 -> NEWARRAY <$> get
      189 -> ANEWARRAY <$> get
      190 -> return ARRAYLENGTH
      191 -> return ATHROW
      192 -> CHECKCAST <$> get
      193 -> INSTANCEOF <$> get
      194 -> return MONITORENTER
      195 -> return MONITOREXIT
      196 -> WIDE <$> get <*> get
      197 -> MULTINANEWARRAY <$> get <*> get
      198 -> IFNULL <$> get
      199 -> IFNONNULL <$> get
      200 -> GOTO_W <$> get
      201 -> JSR_W <$> get
      _ | inRange (59, 62) c -> imm 59 ISTORE_ c
        | inRange (63, 66) c -> imm 63 LSTORE_ c
        | inRange (67, 70) c -> imm 67 FSTORE_ c
        | inRange (71, 74) c -> imm 71 DSTORE_ c
        | inRange (75, 78) c -> imm 75 ASTORE_ c
        | inRange (26, 29) c -> imm 26 ILOAD_ c
        | inRange (30, 33) c -> imm 30 LLOAD_ c
        | inRange (34, 37) c -> imm 34 FLOAD_ c
        | inRange (38, 41) c -> imm 38 DLOAD_ c
        | inRange (42, 45) c -> imm 42 ALOAD_ c
        | inRange (153, 158) c -> IF (toEnum $ fromIntegral $ c-153) <$> get
        | inRange (159, 164) c -> IF_ICMP (toEnum $ fromIntegral $ c-159) <$> get
        | otherwise -> fail $ "Unknown instruction byte code: " ++ show c

-- | Calculate padding for current bytecode offset (cf. TABLESWITCH and LOOKUPSWITCH)
padding :: (Integral a, Integral b) => a -> b
padding offset = fromIntegral $ (4 - offset) `mod` 4

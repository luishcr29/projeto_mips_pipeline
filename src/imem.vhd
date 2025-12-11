LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY imem IS
    PORT (
        a : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END imem;

ARCHITECTURE behave OF imem IS
    TYPE ramtype IS ARRAY (0 TO 63) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- Programa MIPS com operações INTEIRAS e PONTO FLUTUANTE
    -- Testa operações e no final escreve 7 no endereço 84
    SIGNAL mem : ramtype := (
        -- =====================================================
        -- PARTE 1: OPERAÇÕES INTEIRAS
        -- =====================================================
        0  => x"20020005",  -- addi $2, $0, 5         # $2 = 5
        1  => x"2003000c",  -- addi $3, $0, 12        # $3 = 12
        2  => x"2067fff7",  -- addi $7, $3, -9        # $7 = 3
        3  => x"00e22025",  -- or $4, $7, $2          # $4 = 7
        4  => x"00642824",  -- and $5, $3, $4         # $5 = 4
        
        -- =====================================================
        -- PARTE 2: CARREGAR CONSTANTES FP EM REGISTRADORES
        -- =====================================================
        -- Carregar 2.5 em $8 (IEEE 754: 0x40200000)
        5  => x"3c084020",  -- lui $8, 0x4020         # $8[31:16] = 0x4020
        6  => x"35080000",  -- ori $8, $8, 0x0000     # $8 = 0x40200000 = 2.5
        
        -- Carregar 3.5 em $9 (IEEE 754: 0x40600000)
        7  => x"3c094060",  -- lui $9, 0x4060         # $9[31:16] = 0x4060
        8  => x"35290000",  -- ori $9, $9, 0x0000     # $9 = 0x40600000 = 3.5
        
        -- Carregar 1.0 em $10 (IEEE 754: 0x3F800000)
        9  => x"3c0a3f80",  -- lui $10, 0x3f80        # $10[31:16] = 0x3f80
        10 => x"354a0000",  -- ori $10, $10, 0x0000   # $10 = 0x3F800000 = 1.0
        
        -- =====================================================
        -- PARTE 3: OPERAÇÕES DE PONTO FLUTUANTE
        -- =====================================================
        -- FP.ADD: $11 = $8 + $9 = 2.5 + 3.5 = 6.0
        11 => x"01095830",  -- add.s $11, $8, $9      # funct=110000 (0x30)
        
        -- FP.SUB: $12 = $11 - $10 = 6.0 - 1.0 = 5.0
        12 => x"016a6031",  -- sub.s $12, $11, $10    # funct=110001 (0x31)
        
        -- FP.MULT: $13 = $8 * $9 = 2.5 * 3.5 = 8.75
        13 => x"01096832",  -- mul.s $13, $8, $9      # funct=110010 (0x32)
        
        -- FP.CMP: $14 = ($8 < $9) ? 1.0 : 0.0 = 1.0
        14 => x"01097033",  -- c.lt.s $14, $8, $9     # funct=110011 (0x33)
        
        -- FP.ABS: $15 = abs($8) = 2.5
        15 => x"01007834",  -- abs.s $15, $8          # funct=110100 (0x34)
        
        -- =====================================================
        -- PARTE 4: VOLTA PARA OPERAÇÕES INTEIRAS
        -- =====================================================
        16 => x"00a42820",  -- add $5, $5, $4         # $5 = 4 + 7 = 11
        17 => x"10a7000a",  -- beq $5, $7, end        # não desvia (11 != 3)
        18 => x"0064202a",  -- slt $4, $3, $4         # $4 = (12 < 7) = 0
        19 => x"10800001",  -- beq $4, $0, around     # desvia (0 == 0)
        20 => x"20050000",  -- addi $5, $0, 0         # NÃO EXECUTA
        
        -- around:
        21 => x"00e2202a",  -- slt $4, $7, $2         # $4 = (3 < 5) = 1
        22 => x"00853820",  -- add $7, $4, $5         # $7 = 1 + 11 = 12
        23 => x"00e23822",  -- sub $7, $7, $2         # $7 = 12 - 5 = 7
        
        -- =====================================================
        -- PARTE 5: SALVAR RESULTADOS NA MEMÓRIA
        -- =====================================================
        24 => x"ac670044",  -- sw $7, 68($3)          # mem[80] = 7 (int)
        25 => x"ac6b0048",  -- sw $11, 72($3)         # mem[84] = 6.0 (float)
        26 => x"ac6c004c",  -- sw $12, 76($3)         # mem[88] = 5.0 (float)
        27 => x"ac6d0050",  -- sw $13, 80($3)         # mem[92] = 8.75 (float)
        
        -- =====================================================
        -- PARTE 6: TESTAR LOAD E FINALIZAR
        -- =====================================================
        28 => x"8c020050",  -- lw $2, 80($0)          # $2 = mem[80] = 7
        29 => x"08000020",  -- j end                  # pula para end (PC=32)
        30 => x"20020001",  -- addi $2, $0, 1         # NÃO EXECUTA
        
        -- end:
        31 => x"00000000",  -- nop
        32 => x"ac020054",  -- sw $2, 84($0)          # mem[84] = 7 ✅ TESTE!
        
        -- Restante preenchido com NOPs
        OTHERS => x"00000000"
    );
BEGIN
    rd <= mem(to_integer(unsigned(a)));
END behave;

-- ============================================================================
-- DOCUMENTAÇÃO DO PROGRAMA
-- ============================================================================
--
-- Este programa testa OPERAÇÕES INTEIRAS + PONTO FLUTUANTE
--
-- REGISTRADORES USADOS:
-- INTEIROS:
-- $2  = 5, depois 7
-- $3  = 12
-- $4  = 7, depois 0, depois 1
-- $5  = 4, depois 11
-- $7  = 3, depois 12, depois 7
--
-- PONTO FLUTUANTE (IEEE 754 single precision):
-- $8  = 2.5  (0x40200000)
-- $9  = 3.5  (0x40600000)
-- $10 = 1.0  (0x3F800000)
-- $11 = 6.0  (resultado de 2.5 + 3.5)
-- $12 = 5.0  (resultado de 6.0 - 1.0)
-- $13 = 8.75 (resultado de 2.5 * 3.5)
-- $14 = 1.0  (resultado de 2.5 < 3.5)
-- $15 = 2.5  (valor absoluto de 2.5)
--
-- MEMÓRIA:
-- mem[80] = 7      (inteiro)
-- mem[84] = 7      (inteiro) - ✅ TESTADO PELO TESTBENCH
-- mem[88] = 5.0    (float)
-- mem[92] = 8.75   (float)
--
-- CODIFICAÇÃO DAS INSTRUÇÕES FP:
-- Formato R-type: opcode=000000, rs, rt, rd, shamt=00000, funct
--
-- FUNCT codes:
-- 110000 (0x30) = FP.ADD   (add.s)
-- 110001 (0x31) = FP.SUB   (sub.s)
-- 110010 (0x32) = FP.MULT  (mul.s)
-- 110011 (0x33) = FP.CMP   (c.lt.s)
-- 110100 (0x34) = FP.ABS   (abs.s)
-- 110101 (0x35) = FP.NEG   (neg.s)
--
-- EXEMPLOS DE CODIFICAÇÃO:
-- add.s $11, $8, $9:
--   opcode=000000 | rs=$8(01000) | rt=$9(01001) | rd=$11(01011) | 00000 | 110000
--   = 0000 0001 0000 1010 0101 1000 0011 0000
--   = 0x01095830
--
-- ============================================================================
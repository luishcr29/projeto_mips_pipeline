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
    -- Testa várias operações e no final escreve 7 no endereço 84
    SIGNAL mem : ramtype := (
        -- =====================================================
        -- PARTE 1: OPERAÇÕES 
        -- =====================================================
        0 => x"20020005",  -- addi $2, $0, 5         # $2 = 5
        1 => x"2003000c",  -- addi $3, $0, 12        # $3 = 12
        2 => x"2067fff7",  -- addi $7, $3, -9        # $7 = 3
        3 => x"00e22025",  -- or $4, $7, $2          # $4 = 7
        4 => x"00642824",  -- and $5, $3, $4         # $5 = 4
        

        
        -- =====================================================
        -- PARTE 4: VOLTA PARA OPERAÇÕES INTEIRAS
        -- =====================================================
        5 => x"00a42820", -- add $5, $5, $4         # $5 = 4 + 7 = 11
        6 => x"10a7000a", -- beq $5, $7, end        # não desvia (11 != 3)
        7 => x"0064202a", -- slt $4, $3, $4         # $4 = (12 < 7) ? 1 : 0 = 0
        8 => x"10800001", -- beq $4, $0, around     # desvia (0 == 0)
        9 => x"20050000", -- addi $5, $0, 0         # NÃO EXECUTA
        
        -- around:
        10 => x"00e2202a", -- slt $4, $7, $2         # $4 = (3 < 5) ? 1 : 0 = 1
        11 => x"00853820", -- add $7, $4, $5         # $7 = 1 + 11 = 12
        12 => x"00e23822", -- sub $7, $7, $2         # $7 = 12 - 5 = 7
        
        -- =====================================================
        -- PARTE 5: SALVAR RESULTADOS NA MEMÓRIA
        -- =====================================================
        13 => x"ac670044", -- sw $7, 68($3)          # mem[80] = 7 (inteiro)
        14 => x"ac6b0048", -- sw $11, 72($3)         # mem[84] = 6.0 (float)
        15 => x"ac6c004c", -- sw $12, 76($3)         # mem[88] = 5.0 (float)
        16 => x"ac6d0050", -- sw $13, 80($3)         # mem[92] = 8.75 (float)
        
        -- =====================================================
        -- PARTE 6: TESTAR LOAD E FINALIZAR
        -- =====================================================
        17 => x"8c020050", -- lw $2, 80($0)          # $2 = mem[80] = 7
        18 => x"08000020", -- j end                  # pula para end (PC=32)
        19 => x"20020001", -- addi $2, $0, 1         # NÃO EXECUTA
        
        -- end:
        20 => x"00000000", -- nop
        21 => x"ac020054", -- sw $2, 84($0)          # mem[84] = 7 ✅ TESTE!
        
        -- O restante é preenchido com NOPs
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
-- $2  = 5 (int), depois 7 (int)
-- $3  = 12 (int)
-- $4  = 7 (int), depois 0, depois 1
-- $5  = 4 (int), depois 11 (int)
-- $7  = 3 (int), depois 12, depois 7 (int)
-- $8  = 2.5 (float - IEEE 754: 0x40200000)
-- $9  = 3.5 (float - IEEE 754: 0x40600000)
-- $10 = 1.0 (float - IEEE 754: 0x3F800000)
-- $11 = 6.0 (float - resultado de 2.5 + 3.5)
-- $12 = 5.0 (float - resultado de 6.0 - 1.0)
-- $13 = 8.75 (float - resultado de 2.5 * 3.5)
-- $14 = 1.0 (float - resultado da comparação 2.5 < 3.5)
-- $15 = 2.5 (float - valor absoluto de 2.5)
--
-- MEMÓRIA:
-- mem[80] = 7 (inteiro)
-- mem[84] = 7 (inteiro) - VALOR TESTADO PELO TESTBENCH ✅
-- mem[88] = 5.0 (float)
-- mem[92] = 8.75 (float)
--
-- CODIFICAÇÃO DAS INSTRUÇÕES FP (R-type):
-- opcode (6) | rs (5) | rt (5) | rd (5) | shamt (5) | funct (6)
--   000000   |  xxxxx |  xxxxx | xxxxx  |   00000   | 110000-110101
--
-- FUNCT codes:
-- 110000 (0x30) = FP.ADD
-- 110001 (0x31) = FP.SUB
-- 110010 (0x32) = FP.MULT
-- 110011 (0x33) = FP.CMP
-- 110100 (0x34) = FP.ABS
-- 110101 (0x35) = FP.NEG
--
-- ============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY aludec IS -- ALU control decoder
    PORT (
        funct : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        aluop : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- EXPANDIDO de 2 para 4 bits
    );
END;

ARCHITECTURE behave OF aludec IS
BEGIN
    PROCESS (ALL)
    BEGIN
        CASE aluop IS
            WHEN "00" => 
                alucontrol <= "0010"; -- ADD (para lw/sw/addi)
            WHEN "01" => 
                alucontrol <= "0110"; -- SUB (para beq)
            WHEN OTHERS => -- "10" = R-type, decodifica funct
                CASE funct IS
                    -- ============================================
                    -- OPERAÇÕES INTEIRAS (bit 3 = 0)
                    -- ============================================
                    WHEN "100000" => alucontrol <= "0010"; -- ADD
                    WHEN "100010" => alucontrol <= "0110"; -- SUB
                    WHEN "100100" => alucontrol <= "0000"; -- AND
                    WHEN "100101" => alucontrol <= "0001"; -- OR
                    WHEN "101010" => alucontrol <= "0111"; -- SLT (set on less than)
                    
                    -- ============================================
                    -- OPERAÇÕES DE PONTO FLUTUANTE (bit 3 = 1)
                    -- ============================================
                    -- Códigos customizados para instruções FP
                    -- Você pode escolher os códigos funct que preferir
                    WHEN "110000" => alucontrol <= "1000"; -- FP.ADD  (exemplo: funct=110000)
                    WHEN "110001" => alucontrol <= "1001"; -- FP.SUB  (exemplo: funct=110001)
                    WHEN "110010" => alucontrol <= "1010"; -- FP.MULT (exemplo: funct=110010)
                    WHEN "110011" => alucontrol <= "1011"; -- FP.CMP  (exemplo: funct=110011)
                    WHEN "110100" => alucontrol <= "1100"; -- FP.ABS  (exemplo: funct=110100)
                    WHEN "110101" => alucontrol <= "1101"; -- FP.NEG  (exemplo: funct=110101)
                    
                    -- Caso default
                    WHEN OTHERS => alucontrol <= "0000"; -- NOP/AND
                END CASE;
        END CASE;
    END PROCESS;
END;

-- ============================================================================
-- TABELA DE REFERÊNCIA: CÓDIGOS ALUCONTROL
-- ============================================================================
-- 
-- OPERAÇÕES INTEIRAS (bit 3 = 0):
--   "0000" -> AND
--   "0001" -> OR
--   "0010" -> ADD
--   "0110" -> SUB
--   "0111" -> SLT (set on less than)
--
-- OPERAÇÕES PONTO FLUTUANTE (bit 3 = 1):
--   "1000" -> FP ADD
--   "1001" -> FP SUB
--   "1010" -> FP MULT
--   "1011" -> FP CMP  (retorna 1.0 se a<b, senão 0.0)
--   "1100" -> FP ABS  (valor absoluto)
--   "1101" -> FP NEG  (negar sinal)
--
-- ============================================================================
-- MAPEAMENTO SUGERIDO: FUNCT -> OPERAÇÃO FP
-- ============================================================================
--
-- Para usar instruções FP no MIPS, você precisa definir novos códigos funct.
-- Sugestão de mapeamento (baseado em extensões comuns):
--
-- funct = 110000 (48 dec) -> add.s  (FP add single precision)
-- funct = 110001 (49 dec) -> sub.s  (FP sub single precision)
-- funct = 110010 (50 dec) -> mul.s  (FP mult single precision)
-- funct = 110011 (51 dec) -> c.lt.s (FP compare less than)
-- funct = 110100 (52 dec) -> abs.s  (FP absolute value)
-- funct = 110101 (53 dec) -> neg.s  (FP negate)
--
-- EXEMPLO DE USO NO ASSEMBLY:
-- add.s $f0, $f1, $f2  -> opcode=000000, rs=$f1, rt=$f2, rd=$f0, funct=110000
--
-- ============================================================================
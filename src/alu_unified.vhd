LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

--------------------------------------------------------------------------------
-- ALU Unificada: Operações Inteiras + Ponto Flutuante
-- 
-- alucontrol codificação:
-- Operações INTEIRAS (bit 3 = 0):
--   "0000" (000) -> AND
--   "0001" (001) -> OR  
--   "0010" (010) -> ADD
--   "0110" (110) -> SUB
--   "0111" (111) -> SLT
--
-- Operações PONTO FLUTUANTE (bit 3 = 1):
--   "1000" (1000) -> FP ADD
--   "1001" (1001) -> FP SUB
--   "1010" (1010) -> FP MULT
--   "1011" (1011) -> FP CMP (retorna 1.0 se a<b, senão 0.0)
--   "1100" (1100) -> FP ABS
--   "1101" (1101) -> FP NEG
--------------------------------------------------------------------------------

ENTITY alu_unified IS
    PORT (
        clk : IN STD_LOGIC;
        a, b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        alucontrol : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- Expandido para 4 bits
        result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        zero : OUT STD_LOGIC;
        fp_flags : OUT STD_LOGIC_VECTOR(5 DOWNTO 0) -- Flags de comparação FP
    );
END alu_unified;

ARCHITECTURE behave OF alu_unified IS
    -- Componente da ALU de Ponto Flutuante
    COMPONENT fp_alu IS
        PORT (
            clk : IN STD_LOGIC;
            a, b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            fp_op : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            flags : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Sinais internos
    SIGNAL is_fp_op : STD_LOGIC;
    SIGNAL fp_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL int_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL final_result : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    SIGNAL asigned, bsigned : SIGNED(31 DOWNTO 0);
    SIGNAL res_signed : SIGNED(31 DOWNTO 0);
    
BEGIN
    -- Detecta se é operação de ponto flutuante
    is_fp_op <= alucontrol(3);
    
    asigned <= SIGNED(a);
    bsigned <= SIGNED(b);
    
    -- ALU de operações INTEIRAS
    PROCESS(asigned, bsigned, alucontrol)
    BEGIN
        CASE alucontrol(2 DOWNTO 0) IS
            WHEN "010" => -- ADD
                res_signed <= asigned + bsigned;
            WHEN "110" => -- SUB
                res_signed <= asigned - bsigned;
            WHEN "000" => -- AND
                res_signed <= asigned AND bsigned;
            WHEN "001" => -- OR
                res_signed <= asigned OR bsigned;
            WHEN "111" => -- SLT (set on less than)
                IF asigned < bsigned THEN
                    res_signed <= TO_SIGNED(1, 32);
                ELSE
                    res_signed <= TO_SIGNED(0, 32);
                END IF;
            WHEN OTHERS =>
                res_signed <= (OTHERS => '0');
        END CASE;
    END PROCESS;
    
    int_result <= STD_LOGIC_VECTOR(res_signed);
    
    -- ALU de PONTO FLUTUANTE
    fp_alu_inst: fp_alu
        PORT MAP (
            clk => clk,
            a => a,
            b => b,
            fp_op => alucontrol(2 DOWNTO 0),
            result => fp_result,
            flags => fp_flags
        );
    
    -- Multiplexador: seleciona resultado inteiro ou FP
    final_result <= fp_result WHEN is_fp_op = '1' ELSE int_result;
    
    result <= final_result;
    
    -- Flag zero (para operações inteiras e branch)
    zero <= '1' WHEN (is_fp_op = '0' AND res_signed = TO_SIGNED(0, 32)) ELSE '0';
    
END behave;
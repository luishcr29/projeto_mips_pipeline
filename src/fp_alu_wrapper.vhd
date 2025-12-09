-- ALU de Ponto Flutuante usando componentes FloPoCo - CORRIGIDA
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY fp_alu IS
    PORT (
        clk : IN STD_LOGIC;
        a, b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        fp_op : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        flags : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
    );
END fp_alu;

ARCHITECTURE behave OF fp_alu IS
    COMPONENT FPAdd_8_23_comb_uid2 IS
        PORT (
            X : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            Y : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            R : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT FPSub_8_23_comb_uid2 IS
        PORT (
            X : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            Y : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            R : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT FPMult_8_23_uid2_comb_uid3 IS
        PORT (
            X : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            Y : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            R : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT FPComparator_8_23_comb_uid2 IS
        PORT (
            X : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            Y : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
            unordered : OUT STD_LOGIC;
            XltY : OUT STD_LOGIC;
            XeqY : OUT STD_LOGIC;
            XgtY : OUT STD_LOGIC;
            XleY : OUT STD_LOGIC;
            XgeY : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- Sinais internos no formato FloPoCo (34 bits)
    SIGNAL a_flopoco, b_flopoco : STD_LOGIC_VECTOR(33 DOWNTO 0);
    SIGNAL result_add, result_sub, result_mult : STD_LOGIC_VECTOR(33 DOWNTO 0);
    SIGNAL result_flopoco : STD_LOGIC_VECTOR(33 DOWNTO 0);
    
    -- Sinais de comparação
    SIGNAL cmp_unord, cmp_lt, cmp_eq, cmp_gt, cmp_le, cmp_ge : STD_LOGIC;
    
BEGIN
    -- Conversão de entradas IEEE 754 para formato FloPoCo
    PROCESS(a, b)
        VARIABLE exp_a, exp_b : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE frac_a, frac_b : STD_LOGIC_VECTOR(22 DOWNTO 0);
        VARIABLE exc_a, exc_b : STD_LOGIC_VECTOR(1 DOWNTO 0);
    BEGIN
        -- Processa operando A
        exp_a := a(30 DOWNTO 23);
        frac_a := a(22 DOWNTO 0);
        IF exp_a = "00000000" THEN
            exc_a := "00";
        ELSIF exp_a = "11111111" THEN
            IF frac_a = (22 DOWNTO 0 => '0') THEN
                exc_a := "10";
            ELSE
                exc_a := "11";
            END IF;
        ELSE
            exc_a := "01";
        END IF;
        a_flopoco <= exc_a & a;
        
        -- Processa operando B
        exp_b := b(30 DOWNTO 23);
        frac_b := b(22 DOWNTO 0);
        IF exp_b = "00000000" THEN
            exc_b := "00";
        ELSIF exp_b = "11111111" THEN
            IF frac_b = (22 DOWNTO 0 => '0') THEN
                exc_b := "10";
            ELSE
                exc_b := "11";
            END IF;
        ELSE
            exc_b := "01";
        END IF;
        b_flopoco <= exc_b & b;
    END PROCESS;
    
    -- Instancia componentes FloPoCo
    fp_adder: FPAdd_8_23_comb_uid2
        PORT MAP (
            X => a_flopoco,
            Y => b_flopoco,
            R => result_add
        );
    
    fp_subber: FPSub_8_23_comb_uid2
        PORT MAP (
            X => a_flopoco,
            Y => b_flopoco,
            R => result_sub
        );
    
    fp_multiplier: FPMult_8_23_uid2_comb_uid3
        PORT MAP (
            X => a_flopoco,
            Y => b_flopoco,
            R => result_mult
        );
    
    fp_comparator: FPComparator_8_23_comb_uid2
        PORT MAP (
            X => a_flopoco,
            Y => b_flopoco,
            unordered => cmp_unord,
            XltY => cmp_lt,
            XeqY => cmp_eq,
            XgtY => cmp_gt,
            XleY => cmp_le,
            XgeY => cmp_ge
        );
    
    -- Multiplexador de resultados baseado em fp_op
    PROCESS(fp_op, result_add, result_sub, result_mult, a_flopoco, 
            cmp_unord, cmp_lt, cmp_eq, cmp_gt, cmp_le, cmp_ge)
    BEGIN
        CASE fp_op IS
            WHEN "000" => -- FP Add
                result_flopoco <= result_add;
            WHEN "001" => -- FP Sub
                result_flopoco <= result_sub;
            WHEN "010" => -- FP Mult
                result_flopoco <= result_mult;
            WHEN "011" => -- FP Compare (retorna 1.0 ou 0.0)
                IF cmp_lt = '1' THEN
                    result_flopoco <= "01" & "0" & "01111111" & (22 DOWNTO 0 => '0'); -- 1.0
                ELSE
                    result_flopoco <= "00" & (31 DOWNTO 0 => '0'); -- 0.0
                END IF;
            WHEN "100" => -- FP Abs (valor absoluto)
                result_flopoco <= a_flopoco(33 DOWNTO 32) & '0' & a_flopoco(30 DOWNTO 0);
            WHEN "101" => -- FP Neg (negar)
                result_flopoco <= a_flopoco(33 DOWNTO 32) & NOT a_flopoco(31) & a_flopoco(30 DOWNTO 0);
            WHEN OTHERS =>
                result_flopoco <= (OTHERS => '0'); -- Retorna zero para operações inválidas
        END CASE;
    END PROCESS;
    
    -- Conversão de saída: FloPoCo para IEEE 754
    result <= result_flopoco(31 DOWNTO 0);
    
    -- Flags de comparação
    flags <= cmp_unord & cmp_lt & cmp_eq & cmp_gt & cmp_le & cmp_ge;
    
END behave;
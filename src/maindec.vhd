LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY maindec IS -- main control decoder
    PORT (
        op : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        memtoreg, memwrite : OUT STD_LOGIC;
        branch, alusrc : OUT STD_LOGIC;
        regdst, regwrite : OUT STD_LOGIC;
        jump : OUT STD_LOGIC;
        aluop : OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
END;
ARCHITECTURE behave OF maindec IS
    SIGNAL controls : STD_LOGIC_VECTOR(8 DOWNTO 0);
BEGIN
    PROCESS (ALL)
    BEGIN
        CASE op IS
            WHEN "000000" => controls <= "110000010"; -- RTYPE
            WHEN "100011" => controls <= "101001000"; -- LW
            WHEN "101011" => controls <= "001010000"; -- SW
            WHEN "000100" => controls <= "000100001"; -- BEQ
            WHEN "001000" => controls <= "101000000"; -- ADDI
            WHEN "000010" => controls <= "000000100"; -- J
            WHEN OTHERS => controls <= "000000000"; -- illegal op -> all zeros
        END CASE;
    END PROCESS;
    (regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop(1 DOWNTO 0)) <= controls;
END;
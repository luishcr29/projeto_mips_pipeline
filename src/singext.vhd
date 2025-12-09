LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY signext IS
    PORT (
        a : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        y : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END signext;

ARCHITECTURE behave OF signext IS
BEGIN
    PROCESS (a)
    BEGIN
        IF a(15) = '1' THEN
            y <= (31 DOWNTO 16 => '1') & a;
        ELSE
            y <= (31 DOWNTO 16 => '0') & a;
        END IF;
    END PROCESS;
END behave;
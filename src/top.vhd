LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
ENTITY top IS -- top-level design for testing
    PORT (
        clk, reset : IN STD_LOGIC;
        writedata, dataadr : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0);
        memwrite : BUFFER STD_LOGIC);
END;
ARCHITECTURE test OF top IS
    COMPONENT mips PORT (clk, reset : IN STD_LOGIC;
        pc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        memwrite : OUT STD_LOGIC;
        aluout, writedata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        readdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0));
    END COMPONENT;
    COMPONENT imem PORT (a : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
    END COMPONENT;
    COMPONENT dmem PORT (clk, we : IN STD_LOGIC;
        a, wd : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
    END COMPONENT;

    SIGNAL pc, instr, readdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
    -- instantiate processor and memories
    mips1 : mips PORT MAP(clk, reset, pc, instr, memwrite, dataadr, writedata, readdata);
    imem1 : imem PORT MAP(
        a => pc(7 DOWNTO 2),
        rd => instr
    );
    dmem1 : dmem PORT MAP(clk, memwrite, dataadr, writedata, readdata);
END;
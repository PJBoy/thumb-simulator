module emu();
    reg[31:0] r[0:15], memory[0:1023], old_pc;
    reg[15:0] instruction, old_instruction;
    reg[10:0] operand;
    reg[5:0] opcode, old_opcode;
    reg n, z, c, v, clock;

    parameter integer
        lsli      = 0,
        lsri      = 1,
        asri      = 2,
        addr      = 3,
        subr      = 4,
        movi      = 5,
        addi      = 6,
        subi      = 7,
        andr      = 8,
        eorr      = 9,
        lslr      = 10,
        lsrr      = 11,
        negr      = 12,
        orr       = 13,
        mulr      = 14,
        movnr     = 15,
        movrsp    = 16,
        br        = 17,
        ldrpci    = 18,
        strr      = 19,
        ldrr      = 20,
        stri      = 21,
        ldri      = 22,
        strspi    = 23,
        ldrspi    = 24,
        addpci    = 25,
        addspi    = 26,
        incsp     = 27,
        decsp     = 28,
        push      = 29,
        pop       = 30,
        beq       = 31,
        bne       = 32,
        blt       = 33,
        bgt       = 34,
        svc       = 35,
        bu        = 36,
        bl1       = 37,
        bl2       = 38,
        undefined = 39;

    task i_lsli;
        input [2:0] rd;
        input [2:0] rs;
        input [4:0] i;
        begin
            if (i == 5'd0)
                r[rd] = r[rs];
            else
            begin
                r[rd] = r[rs] << i;
                c = r[rs] >> i == 32'd0 ? 1'b0 : 1'b1;
            end
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_lsri;
        input [2:0] rd;
        input [2:0] rs;
        input [4:0] i;
        begin
            if (i == 5'd0)
            begin
                r[rd] = 32'd0;
                z = 1'b1;
                n = 1'b0;
                c = r[rs] == 32'd0 ? 0 : 1;
            end
            else
            begin
                r[rd] = r[rs] >> i;
                c = r[rs] << i == 32'd0 ? 1'b0 : 1'b1;
                z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
                n = r[rd][31];
            end
        end
    endtask

    task i_asri;
        input [2:0] rd;
        input [2:0] rs;
        input [4:0] i;
        begin
            if (i == 5'd0)
            begin
                r[rd] = {32{r[rs][31]}};
                z = r[rs][31];
                n = r[rs][31];
            end
            else
            begin
                r[rd] = $signed(r[rs]) >>> i;
                z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
                n = r[rd][31];
            end
            c = r[rs] << i == 32'd0 ? 1'b0 : 1'b1;
        end
    endtask

    task i_addr;
        input [2:0] rd;
        input [2:0] rs;
        input [2:0] rr;
        begin
            {c, r[rd]} = r[rs] + r[rr];
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
            v = (r[rs][31] ~^ r[rr][31]) & (r[rs][31] ^ r[rd][31]);
        end
    endtask

    task i_subr;
        input [2:0] rd;
        input [2:0] rs;
        input [2:0] rr;
        begin
            {c, r[rd]} = r[rs] + ~r[rr] + 1;
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
            v = (r[rs][31] ^ r[rr][31]) & (r[rs][31] ^ r[rd][31]);
        end
    endtask

    task i_movi;
        input [2:0] rd;
        input [7:0] i;
        begin
            r[rd] = {24'd0, i};
            z = i == 8'd0 ? 1'b1 : 1'b0;
            n = 1'b0;
        end
    endtask

    task i_addi;
        input [2:0] rd;
        input [7:0] i;
        begin
            v = ~r[rd][31];
            {c, r[rd]} = r[rd] + i;
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
            v = v & r[rd][31];
        end
    endtask

    task i_subi;
        input [2:0] rd;
        input [7:0] i;
        begin
            v = r[rd][31];
            {c, r[rd]} = r[rd] + ~i + 1;
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
            v = v & ~r[rd][31];
        end
    endtask

    task i_andr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            r[rd] = r[rd] & r[rs];
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_eorr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            r[rd] = r[rd] ^ r[rs];
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_lslr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            if (r[rs][7:0] != 8'd0)
            begin
                c = r[rd] >> r[rs][7:0] == 32'd0 ? 1'b0 : 1'b1;
                r[rd] = r[rd] << r[rs][7:0];
            end
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_lsrr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            if (r[rs][7:5] != 3'd0)
            begin
                c = r[rd] == 32'd0 ? 0 : 1;
                r[rd] = 32'd0;
                z = 1'b1;
                n = 1'b0;
            end
            else
            begin
                if (r[rs][4:0] != 5'd0)
                begin
                    c = r[rs] << r[rs][4:0] == 32'd0 ? 1'b0 : 1'b1;
                    r[rd] = r[rs] >> r[rs][4:0];
                end
                z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
                n = r[rd][31];
            end
        end
    endtask

    task i_negr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            r[rd] = 0 - r[rd];
            v = r[rs] != 32'h80000000 ? 0 : 1;
            c = r[rs] == 32'd0 ? 1'b0 : 1'b1;
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_orr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            r[rd] = r[rd] | r[rs];
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_mulr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            r[rd] = r[rd] * r[rs];
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_movnr;
        input [2:0] rd;
        input [2:0] rs;
        begin
            r[rd] = ~r[rs];
            z = r[rd] == 32'd0 ? 1'b1 : 1'b0;
            n = r[rd][31];
        end
    endtask

    task i_movrsp;
        input [2:0] rs;
        begin
            r[13] = r[rs];
        end
    endtask

    task i_br;
        input [2:0] rs;
        begin
            r[15] = r[rs] & 32'hFFFFFFFE;
            opcode = 6'd0;
            operand = 11'd0;
            instruction = 16'd0;
        end
    endtask

    task i_ldrpci;
        input [2:0] rd;
        input [7:0] i;
        begin
            r[rd] = memory[(r[15]>>2) + i];
        end
    endtask

    task i_strr;
        input [2:0] rd;
        input [2:0] rs;
        input [2:0] rr;
        begin
            memory[r[rs]+r[rr] >> 2] = r[rd];
        end
    endtask

    task i_ldrr;
        input [2:0] rd;
        input [2:0] rs;
        input [2:0] rr;
        begin
            r[rd] = memory[r[rs]+r[rr] >> 2];
        end
    endtask

    task i_stri;
        input [2:0] rd;
        input [2:0] rs;
        input [4:0] i;
        begin
            memory[(r[rs]>>2) + i] = r[rd];
        end
    endtask

    task i_ldri;
        input [2:0] rd;
        input [2:0] rs;
        input [4:0] i;
        begin
            r[rd] = memory[(r[rs]>>2) + i];
        end
    endtask

    task i_strspi;
        input [2:0] rd;
        input [7:0] i;
        begin
            memory[(r[13]>>2) + i] = r[rd];
        end
    endtask

    task i_ldrspi;
        input [2:0] rd;
        input [7:0] i;
        begin
            r[rd] = memory[(r[13]>>2) + i];
        end
    endtask

    task i_addpci;
        input [2:0] rd;
        input [7:0] i;
        begin
            r[rd] = (r[15]>>2)+i << 2;
        end
    endtask

    task i_addspi;
        input [2:0] rd;
        input [7:0] i;
        begin
            r[rd] = r[13] + (i<<2);
        end
    endtask

    task i_incsp;
        input [6:0] i;
        begin
            r[13] = r[13] + (i<<2);
        end
    endtask

    task i_decsp;
        input [6:0] i;
        begin
            r[13] = r[13] - (i<<2);
        end
    endtask

    task i_push;
        begin
            r[13] = r[13] - 4;
            memory[r[13]>>2] = r[14];
        end
    endtask

    task i_pop;
        begin
            r[15] = memory[r[13]>>2];
            opcode = 6'd0;
            operand = 11'd0;
            instruction = 16'd0;
            r[13] = r[13] + 4;
        end
    endtask

    task i_beq;
        input [7:0] i;
        begin
            if (z == 1'b1)
            begin
                r[15] = r[15] + ($signed(i) << 1);
                opcode = 6'd0;
                operand = 11'd0;
                instruction = 16'd0;
            end
        end
    endtask

    task i_bne;
        input [7:0] i;
        begin
            if (z == 1'b0)
            begin
                r[15] = r[15] + ($signed(i) << 1);
                opcode = 6'd0;
                operand = 11'd0;
                instruction = 16'd0;
            end
        end
    endtask

    task i_blt;
        input [7:0] i;
        begin
            if (n != v)
            begin
                r[15] = r[15] + ($signed(i) << 1);
                opcode = 6'd0;
                operand = 11'd0;
                instruction = 16'd0;
            end
        end
    endtask

    task i_bgt;
        input [7:0] i;
        begin
            if (z==0 && (n == v))
            begin
                r[15] = r[15] + ($signed(i) << 1);
                opcode = 6'd0;
                operand = 11'd0;
                instruction = 16'd0;
            end
        end
    endtask

    integer ii;
    task i_svc;
        input [7:0] i;
        begin
            if (i < 8)
                $display("r%0d=%h", i, r[i]);
            else if (i == 16)
                $display("r0=%h, r1=%h, r2=%h, r3=%h\nr4=%h, r5=%h, r6=%h, r7=%h\nr8=%h, r9=%h, r10=%h, r11=%h\nr12=%h, r13=%h, r14=%h, r15=%h", r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]);
            else if (i == 100)
            begin
                $display("Emulation has stopped due to SVC 100.");
                $finish();
            end
            else if (i == 101)
                for (ii = 32'd0; ii < 1024; ii = ii+1)
                    $display("%h:  %h", ii*4, memory[ii]);
        end
    endtask

    task i_bu;
        input [10:0] i;
        begin
            r[15] = r[15] + ($signed(i) << 1);
            opcode = 6'd0;
            operand = 11'd0;
            instruction = 16'd0;
        end
    endtask

    task i_bl1;
        input [9:0] i;
        begin
            r[14] = r[15] + ($signed(i) << 12);
        end
    endtask

    reg [31:0] t;
    task i_bl2;
        input [10:0] i;
        begin
            t = r[14] + (i << 1);
            r[14] = r[15] - 2;
            r[15] = t;
            opcode = 6'd0;
            operand = 11'd0;
            instruction = 16'd0;
        end
    endtask

    task i_undefined;
        begin
            $display("Error, undefined instruction. Ignoring");
        end
    endtask


    initial
    begin
        $readmemh("input.emu", memory);
        clock = 0;
        r[15] = 32'd0;
        opcode = 6'd0;
        old_opcode = 6'd0;
        operand = 11'd0;
        instruction = 16'd0;
        old_instruction = 16'd0;
    end

    always
        #1 clock = !clock;

    always @(posedge clock)
    begin
        // Execute
        case (opcode)
            lsli:
                i_lsli(operand[2:0], operand[5:3], operand[10:6]);
            lsri:
                i_lsri(operand[2:0], operand[5:3], operand[10:6]);
            asri:
                i_asri(operand[2:0], operand[5:3], operand[10:6]);
            addr:
                i_addr(operand[2:0], operand[5:3], operand[8:6]);
            subr:
                i_subr(operand[2:0], operand[5:3], operand[8:6]);
            movi:
                i_movi(operand[10:8], operand[7:0]);
            addi:
                i_addi(operand[10:8], operand[7:0]);
            subi:
                i_subi(operand[10:8], operand[7:0]);
            andr:
                i_andr(operand[2:0], operand[5:3]);
            eorr:
                i_eorr(operand[2:0], operand[5:3]);
            lslr:
                i_lslr(operand[2:0], operand[5:3]);
            lsrr:
                i_lsrr(operand[2:0], operand[5:3]);
            negr:
                i_negr(operand[2:0], operand[5:3]);
            orr:
                i_orr(operand[2:0], operand[5:3]);
            mulr:
                i_mulr(operand[2:0], operand[5:3]);
            movnr:
                i_movnr(operand[2:0], operand[5:3]);
            movrsp:
                i_movrsp(operand[5:3]);
            br:
                i_br(operand[5:3]);
            ldrpci:
                i_ldrpci(operand[10:8], operand[7:0]);
            strr:
                i_strr(operand[2:0], operand[5:3], operand[8:6]);
            ldrr:
                i_ldrr(operand[2:0], operand[5:3], operand[8:6]);
            stri:
                i_stri(operand[2:0], operand[5:3], operand[10:6]);
            ldri:
                i_ldri(operand[2:0], operand[5:3], operand[10:6]);
            strspi:
                i_strspi(operand[10:8], operand[7:0]);
            ldrspi:
                i_ldrspi(operand[10:8], operand[7:0]);
            addpci:
                i_addpci(operand[10:8], operand[7:0]);
            addspi:
                i_addspi(operand[10:8], operand[7:0]);
            incsp:
                i_incsp(operand[6:0]);
            decsp:
                i_decsp(operand[6:0]);
            push:
                i_push();
            pop:
                i_pop();
            beq:
                i_beq(operand[7:0]);
            bne:
                i_bne(operand[7:0]);
            blt:
                i_blt(operand[7:0]);
            bgt:
                i_bgt(operand[7:0]);
            svc:
                i_svc(operand[7:0]);
            bu:
                i_bu(operand[10:0]);
            bl1:
                i_bl1(operand[9:0]);
            bl2:
                i_bl2(operand[10:0]);
            undefined:
                i_undefined();
        endcase

        // Display
        $write("Executing instruction @ %h: '%b'\nDecoded instruction: ", old_pc-4, old_instruction);
        case (old_opcode)
            lsli:      $display("lsli with rm=%h rd=%h", old_instruction[5:3], old_instruction[2:0]);
            lsri:      $display("lsri with rm=%h rd=%h", old_instruction[5:3], old_instruction[2:0]);
            asri:      $display("asri with rm=%h rd=%h", old_instruction[5:3], old_instruction[2:0]);
            addr:      $display("addr with rm=%h rn=%h rd=%h", old_instruction[8:6], old_instruction[5:3], old_instruction[2:0]);
            subr:      $display("subr with rm=%h rn=%h rd=%h", old_instruction[8:6], old_instruction[5:3], old_instruction[2:0]);
            movi:      $display("movi with rd=%h", old_instruction[10:8]);
            addi:      $display("addi with rdn=%h", old_instruction[10:8]);
            subi:      $display("subi with rdn=%h", old_instruction[10:8]);
            andr:      $display("andr with rdn=%h rm=%h", old_instruction[5:3], old_instruction[2:0]);
            eorr:      $display("eorr with rdn=%h rm=%h", old_instruction[5:3], old_instruction[2:0]);
            lslr:      $display("lslr with rdn=%h rm=%h", old_instruction[5:3], old_instruction[2:0]);
            lsrr:      $display("lsrr with rdn=%h rm=%h", old_instruction[5:3], old_instruction[2:0]);
            negr:      $display("negr with rdn=%h rm=%h", old_instruction[5:3], old_instruction[2:0]);
            orr:       $display("orr with rdn=%h rm=%h", old_instruction[5:3], old_instruction[2:0]);
            mulr:      $display("mulr with rdmn=%h rn=%h", old_instruction[5:3], old_instruction[2:0]);
            movnr:     $display("movnr with rd=%h rm=%h", old_instruction[5:3], old_instruction[2:0]);
            movrsp:    $display("movrsp with rm=%h", old_instruction[5:3]);
            br:        $display("br with rm=%h", old_instruction[5:3]);
            ldrpci:    $display("ldrpci with rd=%h", old_instruction[10:8]);
            strr:      $display("strr with rm=%h rn=%h rt=%h", old_instruction[8:6], old_instruction[5:3], old_instruction[2:0]);
            ldrr:      $display("ldrr with rm=%h rn=%h rt=%h", old_instruction[8:6], old_instruction[5:3], old_instruction[2:0]);
            stri:      $display("stri with rn=%h rt=%h", old_instruction[5:3], old_instruction[2:0]);
            ldri:      $display("ldri with rn=%h rt=%h", old_instruction[5:3], old_instruction[2:0]);
            strspi:    $display("strspi with rt=%h", old_instruction[10:8]);
            ldrspi:    $display("ldrspi with rt=%h", old_instruction[10:8]);
            addpci:    $display("addpci with rd=%h", old_instruction[10:8]);
            addspi:    $display("addspi with rdn=%h", old_instruction[10:8]);
            incsp:     $display("incsp");
            decsp:     $display("decsp");
            push:      $display("push");
            pop:       $display("pop");
            beq:       $display("beq");
            bne:       $display("bne");
            blt:       $display("blt");
            bgt:       $display("bgt");
            svc:       $display("svc");
            bu:        $display("bu");
            bl1:       $display("bl1");
            bl2:       $display("bl2");
            undefined: $display("undefined");
        endcase
        $display("pc=%h, Z = %b, N = %b, C = %b, V = %b\nr0=%h, r1=%h, r2=%h, r3=%h\nr4=%h, r5=%h, r6=%h, r7=%h\nr8=%h, r9=%h, r10=%h, r11=%h\nr12=%h, r13=%h, r14=%h, r15=%h\n", r[15], z, n, c, v, r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]);

        // Decode
        if (instruction[15] == 1'b0)
        begin // 0
            if (instruction[14] == 1'b0)
            begin // 00
                if (instruction[13] == 1'b0)
                begin // 000
                    if (instruction[12] == 1'b0)
                    begin // 0000
                        if (instruction[11] == 1'b0)
                        begin // 00000
                            opcode = lsli;
                        end
                        else
                        begin // 00001
                            opcode = lsri;
                        end
                    end
                    else
                    begin // 0001
                        if (instruction[11] == 1'b0)
                        begin // 00010
                            opcode = asri;
                        end
                        else
                        begin // 00011
                            if (instruction[10] == 1'b0)
                            begin // 000110
                                if (instruction[9] == 1'b0)
                                begin // 0001100
                                    opcode = addr;
                                end
                                else
                                begin // 0001101
                                    opcode = subr;
                                end
                            end
                            else
                            begin // 000111
                                opcode = undefined;
                            end
                        end
                    end
                end
                else
                begin // 001
                    if (instruction[12] == 1'b0)
                    begin // 0010
                        if (instruction[11] == 1'b0)
                        begin // 00100
                            opcode = movi;
                        end
                        else // 00101
                        begin
                            opcode = undefined;
                        end
                    end
                    else
                    begin // 0011
                        if (instruction[11] == 1'b0)
                        begin // 00110
                            opcode = addi;
                        end
                        else
                        begin // 00111
                            opcode = subi;
                        end
                    end
                end
            end
            else
            begin // 01
                if (instruction[13] == 1'b0)
                begin // 010
                    if (instruction[12] == 1'b0)
                    begin // 0100
                        if (instruction[11] == 1'b0)
                        begin // 01000
                            if (instruction[10] == 1'b0)
                            begin // 010000
                                if (instruction[9] == 1'b0)
                                begin // 0100000
                                    if (instruction[8] == 1'b0)
                                    begin // 01000000
                                        if (instruction[7] == 1'b0)
                                        begin // 010000000
                                            if (instruction[6] == 1'b0)
                                            begin // 0100000000
                                                opcode = andr;
                                            end
                                            else
                                            begin // 0100000001
                                                opcode = eorr;
                                            end
                                        end
                                        else
                                        begin // 010000001
                                            if (instruction[6] == 1'b0)
                                            begin // 0100000010
                                                opcode = lslr;
                                            end
                                            else
                                            begin // 0100000011
                                                opcode = lsrr;
                                            end
                                        end
                                    end
                                    else
                                    begin // 01000001
                                        opcode = undefined;
                                    end
                                end
                                else
                                begin // 0100001
                                    if (instruction[8] == 1'b0)
                                    begin // 01000010
                                        if (instruction[7:6] == 2'b01)
                                        begin // 0100001001
                                            opcode = negr;
                                        end
                                        else
                                        begin // 01000010[00|1x]
                                            opcode = undefined;
                                        end
                                    end
                                    else
                                    begin // 01000011
                                        if (instruction[7] == 1'b0)
                                        begin // 010000110
                                            if (instruction[6] == 1'b0)
                                            begin // 0100001100
                                                opcode = orr;
                                            end
                                            else
                                            begin // 0100001101
                                                opcode = mulr;
                                            end
                                        end
                                        else
                                        begin // 010000111
                                            if (instruction[5] == 1'b0)
                                            begin // 0100001110
                                                opcode = undefined;
                                            end
                                            else
                                            begin
                                                // 0100001111
                                                opcode = movnr;
                                            end
                                        end
                                    end
                                end
                            end
                            else
                            begin // 010001
                                if (instruction[9] == 1'b0)
                                begin // 0100010
                                    opcode = undefined;
                                end
                                else
                                begin // 0100011
                                    if (instruction[8] == 1'b0)
                                    begin // 01000110
                                        if (instruction[7:6] == 2'b10 && instruction[2:0] == 3'b101)
                                        begin // 0100011010xxx101
                                            opcode = movrsp;
                                        end
                                        else
                                        begin // 01000110(0x|11)
                                            opcode = undefined;
                                        end
                                    end
                                    else
                                    begin // 01000111
                                        if (instruction[7:6] == 2'b00 && instruction[2:0] == 3'b000)
                                        begin // 0100011100xxx000
                                            opcode = br;
                                        end
                                        else
                                        begin // 01000111(x1|1x)
                                            opcode = undefined;
                                        end
                                    end
                                end
                            end
                        end
                        else
                        begin // 01001
                            opcode = ldrpci;
                        end
                    end
                    else
                    begin // 0101
                        if (instruction[11] == 1'b0)
                        begin // 01010
                            if (instruction[10:9] == 2'b00)
                            begin // 0101000
                                opcode = strr;
                            end
                            else
                            begin // 01010(x1|1x)
                                opcode = undefined;
                            end
                        end
                        else
                        begin // 01011
                            if (instruction[10:9] == 2'b00)
                            begin // 0101100
                                opcode = ldrr;
                            end
                            else
                            begin // 01011(x1|1x)
                                opcode = undefined;
                            end
                        end
                    end
                end
                else
                begin // 011
                    if (instruction[12] == 1'b0)
                    begin // 0110
                        if (instruction[11] == 1'b0)
                        begin // 01100
                            opcode = stri;
                        end
                        else
                        begin // 01101
                            opcode = ldri;
                        end
                    end
                    else
                    begin // 0111
                        opcode = undefined;
                    end
                end
            end
        end
        else
        begin // 1
            if (instruction[14] == 1'b0)
            begin // 10
                if (instruction[13] == 1'b0)
                begin // 100
                    if (instruction[12] == 1'b0)
                    begin // 1000
                        opcode = undefined;
                    end
                    else
                    begin // 1001
                        if (instruction[11] == 1'b0)
                        begin // 10010
                            opcode = strspi;
                        end
                        else
                        begin // 10011
                            opcode = ldrspi;
                        end
                    end
                end
                else
                begin // 101
                    if (instruction[12] == 1'b0)
                    begin // 1010
                        if (instruction[11] == 1'b0)
                        begin // 10100
                            opcode = addpci;
                        end
                        else
                        begin // 10101
                            opcode = addspi;
                        end
                    end
                    else
                    begin // 1011
                        if (instruction[11] == 1'b0)
                        begin // 10110
                            if (instruction[10] == 1'b0)
                            begin // 101100
                                if (instruction[9:8] == 2'b00)
                                begin // 10110000
                                    if (instruction[7] == 1'b0)
                                    begin // 101100000
                                        opcode = incsp;
                                    end
                                    else
                                    begin // 101100001
                                        opcode = decsp;
                                    end
                                end
                                else
                                begin // 101100(x1|1x)
                                    opcode = undefined;
                                end
                            end
                            else
                            begin // 101101
                                if (instruction[9:0] == 10'b0100000000)
                                begin // 1011010100000000
                                    opcode = push;
                                end
                                else
                                begin // 101101(!0100000000)
                                    opcode = undefined;
                                end
                            end
                        end
                        else
                        begin // 10111
                            if (instruction[9:0] == 10'b0100000000)
                            begin // 1011110100000000
                                opcode = pop;
                            end
                            else
                            begin // 10111(!0100000000)
                                opcode = undefined;
                            end
                        end
                    end
                end
            end
            else
            begin // 11
                if (instruction[13] == 1'b0)
                begin // 110
                    if (instruction[12] == 1'b0)
                    begin // 1100
                        opcode = undefined;
                    end
                    else
                    begin // 1101
                        if (instruction[11] == 1'b0)
                        begin // 11010
                            if (instruction[10:9] == 2'b00)
                            begin // 1101000
                                if (instruction[8] == 1'b0)
                                begin // 11010000
                                    opcode = beq;
                                end
                                else
                                begin // 11010001
                                    opcode = bne;
                                end
                            end
                            else
                            begin // 11010(x1|1x)
                                opcode = undefined;
                            end
                        end
                        else
                        begin // 11011
                            if (instruction[10] == 1'b0)
                            begin // 110110
                                if (instruction[9:8] == 2'b11)
                                begin // 11011011
                                    opcode = blt;
                                end
                                else
                                begin // 110110(0x|x0)
                                    opcode = undefined;
                                end
                            end
                            else
                            begin // 110111
                                if (instruction[9] == 1'b0)
                                begin // 1101110
                                    if (instruction[8] == 1'b0)
                                    begin // 11011100
                                        opcode = bgt;
                                    end
                                    else
                                    begin // 11011101
                                        opcode = undefined;
                                    end
                                end
                                else
                                begin // 1101111
                                    if (instruction[8] == 1'b0)
                                    begin // 11011110
                                        opcode = undefined;
                                    end
                                    else
                                    begin // 11011111
                                        opcode = svc;
                                    end
                                end
                            end
                        end
                    end
                end
                else
                begin // 111
                    if (instruction[12] == 1'b0)
                    begin // 1110
                        if (instruction[11] == 1'b0)
                        begin // 11100
                            opcode = bu;
                        end
                        else
                        begin // 11101
                            opcode = undefined;
                        end
                    end
                    else
                    begin // 1111
                        if (instruction[11] == 1'b0)
                        begin // 11110
                            // Choosing to ignore the next bit here, because a BL backwards sets the next bit,
                            // however, i_bl1 is going to ignore this bit to conform with ISA.pdf
                            opcode = bl1;
                        end
                        else
                        begin // 11111
                            opcode = bl2;
                        end
                    end
                end
            end
        end
        old_opcode = opcode;
        operand = instruction[10:0];

        // Fetch
        old_instruction = instruction;
        if (r[15][1] == 0)
            instruction = memory[r[15]>>2][15:0];
        else
            instruction = memory[r[15]>>2][31:16];
        r[15] = r[15] + 2;
        old_pc = r[15];
    end
endmodule

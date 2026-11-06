`timescale 1ns/1ps

module tb_student;

    // Parametro K del DUT (se puede cambiar al compilar con -P tb_student.TB_K=5)
    parameter integer TB_K = 3;

    // Entradas y salida del DUT
    reg         clk;
    reg         rst;
    reg         en;
    reg  [7:0]  cmd;
    reg  [7:0]  data;
    wire [15:0] y;

    // Contadores de la prueba
    integer checks;
    integer errors;

    top_module #(.K(TB_K)) dut (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .cmd (cmd),
        .data(data),
        .y   (y)
    );

    // Reloj de 10 ns
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Un flanco de reloj y 1 ns de espera para que las salidas se asienten
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Compara la salida contra lo esperado: tecla activa y speaker
    task check;
        input [2:0]   exp_key;
        input         exp_spk;
        input [199:0] label;
        begin
            checks = checks + 1;
            if (y !== {12'b0, exp_key, exp_spk}) begin
                errors = errors + 1;
                $display("ERROR [%0s] t=%0t: y=%b esperado=%b",
                         label, $time, y, {12'b0, exp_key, exp_spk});
            end
        end
    endtask

    // Reset sincrono de dos ciclos
    task do_reset;
        begin
            rst = 1'b1;
            tick;
            tick;
            rst = 1'b0;
        end
    endtask

    // Prueba nominal de una tecla sola. El periodo es TB_K + key - 1 flancos
    // habilitados: tras el flanco de seleccion, el speaker alterna al
    // completarse ese numero de flancos adicionales.
    task test_key;
        input [3:0] mask;
        input [2:0] key;
        integer p;
        begin
            p = TB_K + key - 1;
            cmd = 8'h00;
            do_reset;
            cmd = {4'h0, mask};
            tick;                        // flanco de seleccion
            check(key, 1'b0, "tecla seleccionada");
            repeat (p - 1) tick;         // un flanco antes del cambio
            check(key, 1'b0, "speaker aun en 0");
            tick;                        // completa el periodo
            check(key, 1'b1, "primer cambio del speaker");
            repeat (p - 1) tick;
            check(key, 1'b1, "speaker aun en 1");
            tick;
            check(key, 1'b0, "segundo cambio del speaker");
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_student);

        checks = 0;
        errors = 0;
        rst    = 1'b0;
        en     = 1'b1;
        cmd    = 8'h00;
        data   = 8'h00;

        // Prueba inicial: tras el reset todo vale 0
        do_reset;
        check(3'd0, 1'b0, "reset inicial");

        // Sin teclas y con enable, la salida sigue en 0
        repeat (5) tick;
        check(3'd0, 1'b0, "sin teclas");

        // Cada tecla sola
        test_key(4'b0001, 3'd1);
        test_key(4'b0010, 3'd2);
        test_key(4'b0100, 3'd3);
        test_key(4'b1000, 3'd4);

        // Los bits cmd[7:4] se ignoran
        cmd = 8'hF0;
        do_reset;
        tick;
        check(3'd0, 1'b0, "cmd[7:4] ignorados");

        // Reset con una tecla activa: el reset tiene prioridad
        cmd = 8'h00;
        do_reset;
        cmd = 8'h01;
        repeat (TB_K + 1) tick;          // seleccion + un periodo completo
        check(3'd1, 1'b1, "speaker en 1 antes del reset");
        rst = 1'b1;
        tick;
        check(3'd0, 1'b0, "reset con tecla pulsada");
        rst = 1'b0;
        tick;                            // la tecla sigue pulsada: se reselecciona
        check(3'd1, 1'b0, "reseleccion tras soltar reset");

        $display("Resumen: %0d comparaciones, %0d errores", checks, errors);
        if (errors == 0) $display("RESULTADO: OK");
        else             $display("RESULTADO: FALLO");
        $finish;
    end

endmodule

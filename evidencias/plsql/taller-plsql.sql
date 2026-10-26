--------------------------------------------------------------------------------
-- UNIVERSIDAD EL BOSQUE — INGENIERIA DE SISTEMAS
-- Asignatura: Bases de Datos 2
-- Docente: Ing., Esp., M.Ed. Christian Felipe Duarte
--
-- TALLER PL/SQL — PLANTILLA DE ENTREGA
--
-- GRUPO No.: 
-- INTEGRANTES: 1) SAMUEL CAMELO
--              2) DAVID BEJARANO
--              3) SAMUEL NOVOA
-- FECHA DE ENTREGA: ____________
--------------------------------------------------------------------------------
--
-- COMO TRABAJAR
--   1. Ejecute primero, completo, el script 01_esquema_inventario.sql
--   2. Desarrolle cada punto en la seccion correspondiente de este archivo
--   3. No borre los encabezados de cada ejercicio ni cambie los nombres de los
--      objetos solicitados. La revision los busca por nombre: un objeto correcto
--      con otro nombre se califica como no entregado.
--   4. Los esqueletos de la Parte 5 no incluyen la clausula de disparo. Definirla
--      hace parte del ejercicio, de modo que esos bloques no compilan tal como se
--      entregan.
--
-- DISTRIBUCION DEL PUNTAJE                                     Total: 50 puntos
--   Parte 1  Procedimientos almacenados .................  8 puntos
--   Parte 2  Funciones ...................................  8 puntos
--   Parte 3  Cursores .................................... 10 puntos
--   Parte 4  Manejo de excepciones .......................  9 puntos
--   Parte 5  Disparadores ................................ 10 puntos
--   Parte 6  Caso integrador .............................  5 puntos
--
-- CRITERIOS DE EVALUACION
--   Correccion tecnica ....... 40%   El objeto compila y cumple el enunciado
--   Justificacion ............ 40%   Las decisiones de diseno estan argumentadas
--   Analisis operacional ..... 20%   Se anticipa el comportamiento ante
--                                    concurrencia, volumen y error
--
--   Cada objeto debe incluir su justificacion en el espacio marcado. Un ejercicio
--   sin justificacion obtiene como maximo el 40% de su puntaje aunque funcione.
--   Una justificacion que confunde la causa con el efecto no obtiene puntaje.
--   Describir lo que hace el codigo, sin argumentar por que se eligio esa
--   construccion y no otra, equivale a no justificar.
--
-- ENTREGA
--   Este archivo renombrado como TALLER_PLSQL_GRUPO_<n>.sql, junto con un
--   documento que contenga las salidas de DBMS_OUTPUT de cada bloque ejecutado.
--   Ambos archivos deben incluir los nombres de los tres integrantes.
--
-- SUSTENTACION
--   20 minutos por grupo. Los tres integrantes deben poder explicar cualquier
--   parte del codigo, no solamente la que desarrollaron.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED

--==============================================================================
-- PARTE 1 — PROCEDIMIENTOS ALMACENADOS                        (8 puntos / 75 min)
--==============================================================================


------------------------------------------------------------------- 1.1 (2 pts)
-- SP_REGISTRAR_PRODUCTO
-- Registra un producto nuevo. Debe asignar el identificador desde SEQ_PRODUCTO,
-- validar que el precio de venta supere el costo unitario, verificar que la
-- categoria exista y manejar el caso de codigo duplicado. Devuelve el
-- identificador generado.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El procedimiento valida que el precio de venta sea mayor que el costo unitario y que la categoría indicada exista antes de registrar
-- el producto. El identificador del nuevo producto se genera automáticamente mediante SEQ_PRODUCTO.NEXTVAL, garantizando un valor único
-- para la llave primaria y devolviéndolo por medio del parámetro OUT.
-- Además, se controla el caso de códigos duplicados mediante la excepción DUP_VAL_ON_INDEX, mostrando un mensaje de error personalizado.

CREATE OR REPLACE PROCEDURE SP_REGISTRAR_PRODUCTO (
    param_codigo        IN  VARCHAR2,
    param_nombre        IN  VARCHAR2,
    param_id_categoria  IN  NUMBER,
    param_precio        IN  NUMBER,
    param_costo         IN  NUMBER,
    param_stock_minimo  IN  NUMBER DEFAULT 0,
    param_id_producto   OUT NUMBER
) IS

    vn_categoria NUMBER;

    e_precio_invalido     EXCEPTION;
    e_categoria_no_existe EXCEPTION;

BEGIN

    IF param_precio <= param_costo THEN
        RAISE e_precio_invalido;
    END IF;


    SELECT COUNT(*)
    INTO vn_categoria
    FROM CATEGORIA
    WHERE id_categoria = param_id_categoria;


    IF vn_categoria = 0 THEN
        RAISE e_categoria_no_existe;
    END IF;


    param_id_producto := SEQ_PRODUCTO.NEXTVAL;


    INSERT INTO PRODUCTO (
        id_producto,
        codigo,
        nombre,
        id_categoria,
        precio_unitario,
        costo_unitario,
        stock_minimo,
        activo
    )
    VALUES (
        param_id_producto,
        param_codigo,
        param_nombre,
        param_id_categoria,
        param_precio,
        param_costo,
        param_stock_minimo,
        'S'
    );


EXCEPTION

    WHEN e_precio_invalido THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'El precio de venta debe ser mayor que el costo unitario'
        );


    WHEN e_categoria_no_existe THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'La categoria indicada no existe'
        );


    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Ya existe un producto con el codigo ' || param_codigo
        );


END SP_REGISTRAR_PRODUCTO;
/

--
-- PRUEBAS
--

SHOW ERRORS PROCEDURE SP_REGISTRAR_PRODUCTO;

SET SERVEROUTPUT ON;


DECLARE
    vn_id NUMBER;
BEGIN

    SP_REGISTRAR_PRODUCTO(
        param_codigo       => 'TEST-001',
        param_nombre       => 'Producto de prueba',
        param_id_categoria => 1,
        param_precio       => 50000,
        param_costo        => 30000,
        param_stock_minimo => 10,
        param_id_producto  => vn_id
    );

    DBMS_OUTPUT.PUT_LINE('Producto creado con ID: ' || vn_id);

END;
/


SELECT id_producto,
       codigo,
       nombre
FROM PRODUCTO
WHERE codigo = 'TEST-001';

SELECT MAX(id_producto) AS max_id
FROM PRODUCTO;

SELECT SEQ_PRODUCTO.NEXTVAL AS siguiente_id
FROM DUAL;

SELECT id_producto,
       codigo,
       nombre
FROM PRODUCTO
WHERE id_producto = 1012;

ALTER SEQUENCE SEQ_PRODUCTO INCREMENT BY 3;

SELECT SEQ_PRODUCTO.NEXTVAL
FROM DUAL;

ALTER SEQUENCE SEQ_PRODUCTO INCREMENT BY 1;

SELECT MAX(id_producto) AS max_id
FROM PRODUCTO;

SELECT SEQ_PRODUCTO.NEXTVAL AS siguiente_id
FROM DUAL;

DECLARE
    vn_id NUMBER;
BEGIN

    SP_REGISTRAR_PRODUCTO(
        param_codigo       => 'TEST-002',
        param_nombre       => 'Producto precio invalido',
        param_id_categoria => 1,
        param_precio       => 20000,
        param_costo        => 30000,
        param_stock_minimo => 5,
        param_id_producto  => vn_id
    );

END;
/


DECLARE
    vn_id NUMBER;
BEGIN

    SP_REGISTRAR_PRODUCTO(
        param_codigo       => 'TEST-003',
        param_nombre       => 'Producto categoria invalida',
        param_id_categoria => 99,
        param_precio       => 50000,
        param_costo        => 30000,
        param_stock_minimo => 5,
        param_id_producto  => vn_id
    );

END;
/



------------------------------------------------------------------- 1.2 (3 pts)
-- SP_AJUSTAR_STOCK
-- Registra una ENTRADA, SALIDA o AJUSTE de inventario sobre una bodega.
-- Debe actualizar EXISTENCIA e insertar el registro en MOVIMIENTO_INVENTARIO,
-- devolviendo el saldo resultante.
--   * Si la combinacion bodega-producto no existe y el tipo es ENTRADA, crearla
--   * Si el tipo es SALIDA y no existe la combinacion, rechazar la operacion
--   * Una SALIDA nunca puede dejar la existencia en negativo
-- Proteja la lectura de la existencia frente a modificaciones concurrentes.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El procedimiento valida que el tipo de movimiento sea ENTRADA, SALIDA o AJUSTE y que la cantidad sea mayor que cero.
-- La existencia del producto en la bodega se consulta mediante SELECT y FOR UPDATE para bloquear el registro mientras
-- se realiza la operación y evitar inconsistencias por accesos concurrentes. En una ENTRADA se incrementa el stock y, si la
-- combinación producto-bodega no existe, se crea. En una SALIDA se verifica que exista inventario suficiente para evitar saldos
-- negativos. En un AJUSTE se actualiza la existencia al valor indicado. Finalmente, se registra el movimiento en MOVIMIENTO_INVENTARIO
-- usando SEQ_MOVIMIENTO.NEXTVAL y se devuelve el saldo resultante mediante el parámetro OUT.

CREATE OR REPLACE PROCEDURE SP_AJUSTAR_STOCK (
    param_id_producto  IN  NUMBER,
    param_id_bodega    IN  NUMBER,
    param_tipo         IN  VARCHAR2,
    param_cantidad     IN  NUMBER,
    param_observacion  IN  VARCHAR2 DEFAULT NULL,
    param_saldo_final  OUT NUMBER
) IS

    vn_existencia NUMBER;

    e_tipo_invalido        EXCEPTION;
    e_cantidad_invalida    EXCEPTION;
    e_existencia_no_existe EXCEPTION;
    e_stock_insuficiente   EXCEPTION;

BEGIN

    IF UPPER(param_tipo) NOT IN ('ENTRADA', 'SALIDA', 'AJUSTE') THEN
        RAISE e_tipo_invalido;
    END IF;


    IF param_cantidad <= 0 THEN
        RAISE e_cantidad_invalida;
    END IF;


    BEGIN

        SELECT cantidad
        INTO vn_existencia
        FROM EXISTENCIA
        WHERE id_producto = param_id_producto
          AND id_bodega = param_id_bodega
        FOR UPDATE;


    EXCEPTION

        WHEN NO_DATA_FOUND THEN

            IF UPPER(param_tipo) = 'ENTRADA' THEN

                INSERT INTO EXISTENCIA (
                    id_bodega,
                    id_producto,
                    cantidad
                )
                VALUES (
                    param_id_bodega,
                    param_id_producto,
                    param_cantidad
                );

                param_saldo_final := param_cantidad;

            ELSE

                -- SALIDA o AJUSTE sobre una existencia inexistente
                RAISE e_existencia_no_existe;

            END IF;

    END;


    IF vn_existencia IS NOT NULL
       AND UPPER(param_tipo) = 'ENTRADA' THEN

        param_saldo_final := vn_existencia + param_cantidad;

        UPDATE EXISTENCIA
        SET cantidad = param_saldo_final
        WHERE id_producto = param_id_producto
          AND id_bodega = param_id_bodega;


    ELSIF vn_existencia IS NOT NULL
       AND UPPER(param_tipo) = 'SALIDA' THEN

        IF param_cantidad > vn_existencia THEN
            RAISE e_stock_insuficiente;
        END IF;

        param_saldo_final := vn_existencia - param_cantidad;

        UPDATE EXISTENCIA
        SET cantidad = param_saldo_final
        WHERE id_producto = param_id_producto
          AND id_bodega = param_id_bodega;


    ELSIF vn_existencia IS NOT NULL
       AND UPPER(param_tipo) = 'AJUSTE' THEN

        param_saldo_final := param_cantidad;

        UPDATE EXISTENCIA
        SET cantidad = param_saldo_final
        WHERE id_producto = param_id_producto
          AND id_bodega = param_id_bodega;

    END IF;


    INSERT INTO MOVIMIENTO_INVENTARIO (
        id_movimiento,
        id_producto,
        id_bodega,
        tipo,
        cantidad,
        fecha_mov,
        usuario_bd,
        observacion
    )
    VALUES (
        SEQ_MOVIMIENTO.NEXTVAL,
        param_id_producto,
        param_id_bodega,
        UPPER(param_tipo),
        param_cantidad,
        SYSDATE,
        USER,
        param_observacion
    );


EXCEPTION

    WHEN e_tipo_invalido THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'El tipo de movimiento debe ser ENTRADA, SALIDA o AJUSTE'
        );


    WHEN e_cantidad_invalida THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'La cantidad debe ser mayor que cero'
        );


    WHEN e_existencia_no_existe THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'No existe inventario para el producto en la bodega indicada'
        );


    WHEN e_stock_insuficiente THEN
        RAISE_APPLICATION_ERROR(
            -20007,
            'La salida supera la existencia disponible'
        );


END SP_AJUSTAR_STOCK;
/


---------------------------------------
-- PRUEBAS
---------------------------------------

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'SP_AJUSTAR_STOCK';


SELECT *
FROM EXISTENCIA
WHERE id_producto = 1001
  AND id_bodega = 1;


SET SERVEROUTPUT ON;


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1001,
        param_id_bodega   => 1,
        param_tipo        => 'ENTRADA',
        param_cantidad    => 10,
        param_observacion => 'Prueba entrada',
        param_saldo_final => vn_saldo
    );

    DBMS_OUTPUT.PUT_LINE('Saldo final: ' || vn_saldo);

END;
/


SELECT *
FROM MOVIMIENTO_INVENTARIO
WHERE id_producto = 1001
  AND id_bodega = 1
ORDER BY id_movimiento DESC;


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1001,
        param_id_bodega   => 1,
        param_tipo        => 'SALIDA',
        param_cantidad    => 5,
        param_observacion => 'Prueba salida',
        param_saldo_final => vn_saldo
    );

    DBMS_OUTPUT.PUT_LINE('Saldo final: ' || vn_saldo);

END;
/


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1001,
        param_id_bodega   => 1,
        param_tipo        => 'SALIDA',
        param_cantidad    => 999999,
        param_observacion => 'Prueba stock insuficiente',
        param_saldo_final => vn_saldo
    );

END;
/


SELECT *
FROM EXISTENCIA
WHERE id_producto = 1014
  AND id_bodega = 2;


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1014,
        param_id_bodega   => 2,
        param_tipo        => 'ENTRADA',
        param_cantidad    => 25,
        param_observacion => 'Nueva existencia',
        param_saldo_final => vn_saldo
    );

    DBMS_OUTPUT.PUT_LINE('Saldo final: ' || vn_saldo);

END;
/


SELECT *
FROM EXISTENCIA
WHERE id_producto = 1015
  AND id_bodega = 4;


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1015,
        param_id_bodega   => 4,
        param_tipo        => 'SALIDA',
        param_cantidad    => 5,
        param_observacion => 'Prueba inexistente',
        param_saldo_final => vn_saldo
    );

END;
/


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1001,
        param_id_bodega   => 1,
        param_tipo        => 'VENTA',
        param_cantidad    => 5,
        param_observacion => 'Tipo invalido',
        param_saldo_final => vn_saldo
    );

END;
/


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1001,
        param_id_bodega   => 1,
        param_tipo        => 'ENTRADA',
        param_cantidad    => 0,
        param_observacion => 'Cantidad invalida',
        param_saldo_final => vn_saldo
    );

END;
/


DECLARE
    vn_saldo NUMBER;
BEGIN

    SP_AJUSTAR_STOCK(
        param_id_producto => 1001,
        param_id_bodega   => 1,
        param_tipo        => 'AJUSTE',
        param_cantidad    => 50,
        param_observacion => 'Conteo fisico',
        param_saldo_final => vn_saldo
    );

    DBMS_OUTPUT.PUT_LINE('Saldo final: ' || vn_saldo);

END;
/



------------------------------------------------------------------- 1.3 (3 pts)
-- SP_CREAR_PEDIDO
-- Crea la cabecera de un pedido en estado BORRADOR y devuelve el identificador
-- generado. Debe rechazar clientes inactivos y clientes sin cupo de credito
-- disponible, con mensajes distinguibles entre si.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El procedimiento valida que el cliente exista, se encuentre activo y tenga cupo de crédito disponible antes de crear el pedido.
-- Para determinar el cupo disponible se calcula la diferencia entre cupo_credito y saldo_pendiente. Se utilizan excepciones
-- independientes para distinguir los casos de cliente inexistente, cliente inactivo y cliente sin cupo disponible. Si todas
-- las validaciones se cumplen, se genera el identificador del pedido mediante SEQ_PEDIDO.NEXTVAL, se crea la cabecera en estado
-- BORRADOR con total inicial de 0 y se devuelve el identificador generado mediante el parámetro OUT.

CREATE OR REPLACE PROCEDURE SP_CREAR_PEDIDO (
    param_id_cliente  IN  NUMBER,
    param_id_pedido   OUT NUMBER
) IS

    vc_activo           CLIENTE.activo%TYPE;
    vn_cupo_credito     CLIENTE.cupo_credito%TYPE;
    vn_saldo_pendiente  CLIENTE.saldo_pendiente%TYPE;
    vn_cupo_disponible  NUMBER;

    e_cliente_no_existe EXCEPTION;
    e_cliente_inactivo  EXCEPTION;
    e_sin_cupo          EXCEPTION;

BEGIN

    BEGIN

        SELECT activo,
               cupo_credito,
               saldo_pendiente
        INTO   vc_activo,
               vn_cupo_credito,
               vn_saldo_pendiente
        FROM CLIENTE
        WHERE id_cliente = param_id_cliente;


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE e_cliente_no_existe;

    END;


    IF vc_activo = 'N' THEN
        RAISE e_cliente_inactivo;
    END IF;


    vn_cupo_disponible := vn_cupo_credito - vn_saldo_pendiente;


    IF vn_cupo_disponible <= 0 THEN
        RAISE e_sin_cupo;
    END IF;


    param_id_pedido := SEQ_PEDIDO.NEXTVAL;


    INSERT INTO PEDIDO (
        id_pedido,
        id_cliente,
        fecha_pedido,
        estado,
        total
    )
    VALUES (
        param_id_pedido,
        param_id_cliente,
        SYSDATE,
        'BORRADOR',
        0
    );


EXCEPTION

    WHEN e_cliente_no_existe THEN
        RAISE_APPLICATION_ERROR(
            -20008,
            'El cliente indicado no existe'
        );


    WHEN e_cliente_inactivo THEN
        RAISE_APPLICATION_ERROR(
            -20009,
            'El cliente se encuentra inactivo'
        );


    WHEN e_sin_cupo THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'El cliente no tiene cupo de credito disponible'
        );


END SP_CREAR_PEDIDO;
/


---------------------------------
-- PRUEBA
----------------------------------

DECLARE
    vn_id_pedido NUMBER;
BEGIN

    SP_CREAR_PEDIDO(
        param_id_cliente => 501,
        param_id_pedido  => vn_id_pedido
    );

    DBMS_OUTPUT.PUT_LINE('Pedido creado con ID: ' || vn_id_pedido);

END;
/


SELECT *
FROM PEDIDO
WHERE id_cliente = 501
ORDER BY id_pedido DESC;


DECLARE
    vn_id_pedido NUMBER;
BEGIN

    SP_CREAR_PEDIDO(
        param_id_cliente => 506,
        param_id_pedido  => vn_id_pedido
    );

END;
/


DECLARE
    vn_id_pedido NUMBER;
BEGIN

    SP_CREAR_PEDIDO(
        param_id_cliente => 505,
        param_id_pedido  => vn_id_pedido
    );

END;
/


DECLARE
    vn_id_pedido NUMBER;
BEGIN

    SP_CREAR_PEDIDO(
        param_id_cliente => 9999,
        param_id_pedido  => vn_id_pedido
    );

END;
/

--==============================================================================
-- PARTE 2 — FUNCIONES                                         (8 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 2.1 (2 pts)
-- FN_STOCK_DISPONIBLE
-- Retorna la cantidad disponible de un producto. Si se indica bodega, devuelve
-- el saldo de esa bodega; si p_id_bodega llega nulo, el consolidado de todas.
-- Un producto inexistente debe retornar cero y no una excepcion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Se utiliza la funcion de grupo SUM() combinada con NVL(). Esto permite que 
-- la agregacion en una sola fila procese tanto el calculo del total como el 
-- manejo de nulos (producto sin stock o inexistente) sin necesidad de recurrir 
-- a un bloque EXCEPTION para NO_DATA_FOUND. Las funciones de grupo sin GROUP BY 
-- siempre devuelven una fila con valor NULL si no hay coincidencias, lo cual es 
-- transformado eficientemente a 0 por NVL, evitando excepciones costosas en 
-- tiempo de ejecucion.
CREATE OR REPLACE FUNCTION fn_stock_disponible (
    param_id_producto IN NUMBER,
    param_id_bodega   IN NUMBER DEFAULT NULL
) RETURN NUMBER IS
    vn_stock_total NUMBER;
BEGIN
    SELECT NVL(SUM(cantidad), 0)
    INTO vn_stock_total
    FROM EXISTENCIA
    WHERE id_producto = param_id_producto
      AND (id_bodega = param_id_bodega OR param_id_bodega IS NULL);

    RETURN vn_stock_total;
END fn_stock_disponible;
/

------------------------------------------------------------------- 2.2 (2 pts)
-- FN_CUPO_DISPONIBLE
-- Retorna el cupo de credito disponible del cliente, entendido como cupo menos
-- saldo pendiente. Un cliente inactivo retorna cero y el resultado nunca puede
-- ser negativo.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Se delega la logica de limites al motor SQL utilizando la funcion GREATEST() 
-- para asegurar nativamente que el valor minimo retornado sea 0 en caso de un 
-- saldo negativo, evitando multiples sentencias condicionales IF en PL/SQL. 
-- Asimismo, la validacion del cliente inactivo se maneja de forma elegante en 
-- el mismo nivel SQL con un CASE, reduciendo los cambios de contexto (Context 
-- Switches) entre el motor PL/SQL y el motor SQL, optimizando el rendimiento.
CREATE OR REPLACE FUNCTION fn_cupo_disponible (
    param_id_cliente IN NUMBER
) RETURN NUMBER IS
    vn_cupo_disponible NUMBER;
BEGIN
    SELECT CASE 
               WHEN activo = 'N' THEN 0
               ELSE GREATEST(cupo_credito - saldo_pendiente, 0)
           END
    INTO vn_cupo_disponible
    FROM CLIENTE
    WHERE id_cliente = param_id_cliente;

    RETURN vn_cupo_disponible;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END fn_cupo_disponible;
/

------------------------------------------------------------------- 2.3 (3 pts)
-- FN_CALCULAR_DESCUENTO
-- Retorna el VALOR en pesos del descuento aplicable, segun estas reglas
-- acumulables:
--     Monto mayor o igual a 2.000.000 ................. 8%
--     Monto entre 800.000 y 1.999.999 ................. 5%
--     Monto menor a 800.000 ........................... 0%
--     Adicional si el cliente no tiene saldo pendiente . 2%
--     Tope maximo acumulado ........................... 10%
-- La funcion retorna el valor del descuento, no el porcentaje.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El diseno separa la obtencion del porcentaje base (mediante IF/ELSIF segun 
-- param_monto) de la bonificacion adicional. El tope maximo acumulado se impone 
-- sin condicionales extra utilizando la funcion LEAST(x, 10), garantizando que 
-- si la sumatoria de porcentajes da 11% o mas, se cape nativamente a 10. Por 
-- ultimo, la funcion retorna directamente la operacion matematica sobre param_monto,
-- cumpliendo estrictamente con devolver el valor nominal y no el porcentual.  
CREATE OR REPLACE FUNCTION fn_calcular_descuento (
    param_id_cliente IN NUMBER,
    param_monto      IN NUMBER
) RETURN NUMBER IS
    vn_porcentaje_base      NUMBER := 0;
    vn_porcentaje_adicional NUMBER := 0;
    vn_porcentaje_total     NUMBER := 0;
    vn_saldo_pendiente      CLIENTE.saldo_pendiente%TYPE;
BEGIN
    IF param_monto >= 2000000 THEN
        vn_porcentaje_base := 8;
    ELSIF param_monto >= 800000 THEN
        vn_porcentaje_base := 5;
    ELSE
        vn_porcentaje_base := 0;
    END IF;

    SELECT saldo_pendiente 
    INTO vn_saldo_pendiente
    FROM CLIENTE 
    WHERE id_cliente = param_id_cliente;

    IF vn_saldo_pendiente = 0 THEN
        vn_porcentaje_adicional := 2;
    END IF;

    vn_porcentaje_total := LEAST(vn_porcentaje_base + vn_porcentaje_adicional, 10);

    RETURN (param_monto * vn_porcentaje_total) / 100;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; 
END fn_calcular_descuento;
/

------------------------------------------------------------------- 2.4 (1 pt)
-- Escriba una consulta que liste los clientes activos con su cupo disponible,
-- usando la funcion del punto 2.2, ordenados de mayor a menor.
-- Explique por que una funcion definida por el usuario puede invocarse desde
-- una sentencia SQL y que restriccion debe cumplir para poder hacerlo.
-------------------------------------------------------------------------------
-- RESPUESTA:
-- Para que una funcion PL/SQL (fn) pueda invocarse desde una consulta SQL, 
-- debe cumplir con el nivel de pureza WNDS (Write No Database State). Esto 
-- significa que la funcion no puede modificar datos de las tablas de la base 
-- de datos (no puede incluir sentencias INSERT, UPDATE, DELETE). Al ser solo 
-- de lectura o calculo, el motor SQL confia en ella para integrarla fila a fila.
--
SELECT id_cliente,
       documento,
       nombre,
       fn_cupo_disponible(id_cliente) AS cupo_disponible
FROM CLIENTE
WHERE activo = 'S'
ORDER BY cupo_disponible DESC;
--==============================================================================
-- PARTE 3 — CURSORES                                         (10 puntos / 90 min)
--==============================================================================

------------------------------------------------------------------- 3.1 (2 pts)
-- Bloque anonimo que recorra, con un CURSOR EXPLICITO, los productos cuyo stock
-- consolidado este por debajo del stock minimo, e imprima un reporte con codigo,
-- nombre, stock actual, stock minimo y unidades faltantes, mas el total de
-- productos en esa condicion.
-- Debe usar OPEN, FETCH y CLOSE de forma explicita. El ciclo FOR implicito no se
-- acepta en este punto.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Se utiliza un cursor explicito para consultar los productos cuyo stock
-- consolidado es inferior al stock minimo. El cursor se controla manualmente
-- mediante OPEN, FETCH y CLOSE, permitiendo recorrer cada registro e imprimir
-- el codigo, nombre, stock actual, stock minimo y las unidades faltantes.
-- Adicionalmente, se utiliza una variable numerica para contar la cantidad total
-- de productos que se encuentran por debajo del stock minimo.

DECLARE

    CURSOR cur_productos_bajo_minimo IS
        SELECT codigo,
               producto,
               stock_total,
               stock_minimo,
               stock_minimo - stock_total AS unidades_faltantes
        FROM V_STOCK_CONSOLIDADO
        WHERE stock_total < stock_minimo
        ORDER BY codigo;


    r_producto cur_productos_bajo_minimo%ROWTYPE;

    vn_total_productos NUMBER := 0;

BEGIN

    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE(' PRODUCTOS POR DEBAJO DEL STOCK MINIMO');
    DBMS_OUTPUT.PUT_LINE('==============================================');


    OPEN cur_productos_bajo_minimo;


    LOOP

        FETCH cur_productos_bajo_minimo
        INTO r_producto;


        EXIT WHEN cur_productos_bajo_minimo%NOTFOUND;


        vn_total_productos := vn_total_productos + 1;


        DBMS_OUTPUT.PUT_LINE(
            'Codigo: ' || r_producto.codigo ||
            ' | Producto: ' || r_producto.producto ||
            ' | Stock actual: ' || r_producto.stock_total ||
            ' | Stock minimo: ' || r_producto.stock_minimo ||
            ' | Faltantes: ' || r_producto.unidades_faltantes
        );

    END LOOP;


    CLOSE cur_productos_bajo_minimo;


    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(
        'Total de productos bajo minimo: ' || vn_total_productos
    );

END;
/
------------------------------------------------------------------- 3.2 (2 pts)
-- Bloque anonimo con un CURSOR PARAMETRIZADO que reciba identificador de cliente
-- y un rango de fechas, y muestre los pedidos CONFIRMADOS de ese cliente en ese
-- rango, con su total y la cantidad de lineas de cada pedido.
-- Pruebelo con el cliente 501 entre 2026-01-01 y 2026-12-31.
-- Los parametros deben declararse en el cursor, no tomarse del alcance del bloque.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Se utiliza un cursor parametrizado para permitir consultar los pedidos de
-- diferentes clientes y rangos de fechas sin modificar la consulta del cursor.
-- Los parametros se declaran directamente dentro del cursor, como exige el
-- enunciado. Se seleccionan solamente pedidos en estado CONFIRMADO y se utiliza
-- COUNT sobre DETALLE_PEDIDO para obtener la cantidad de lineas de cada pedido.

DECLARE

    CURSOR cur_pedidos_cliente (
        param_id_cliente   NUMBER,
        param_fecha_inicio DATE,
        param_fecha_fin    DATE
    ) IS
        SELECT p.id_pedido,
               p.fecha_pedido,
               p.total,
               COUNT(dp.linea) AS cantidad_lineas
        FROM PEDIDO p
        LEFT JOIN DETALLE_PEDIDO dp
               ON dp.id_pedido = p.id_pedido
        WHERE p.id_cliente = param_id_cliente
          AND p.estado = 'CONFIRMADO'
          AND p.fecha_pedido >= param_fecha_inicio
          AND p.fecha_pedido < param_fecha_fin + 1
        GROUP BY p.id_pedido,
                 p.fecha_pedido,
                 p.total
        ORDER BY p.fecha_pedido;


    r_pedido cur_pedidos_cliente%ROWTYPE;

    vb_encontro BOOLEAN := FALSE;

BEGIN

    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE(' PEDIDOS CONFIRMADOS DEL CLIENTE 501');
    DBMS_OUTPUT.PUT_LINE('==============================================');


    OPEN cur_pedidos_cliente(
        501,
        TO_DATE('2026-01-01', 'YYYY-MM-DD'),
        TO_DATE('2026-12-31', 'YYYY-MM-DD')
    );


    LOOP

        FETCH cur_pedidos_cliente
        INTO r_pedido;


        EXIT WHEN cur_pedidos_cliente%NOTFOUND;


        vb_encontro := TRUE;


        DBMS_OUTPUT.PUT_LINE(
            'Pedido: ' || r_pedido.id_pedido ||
            ' | Fecha: ' || TO_CHAR(r_pedido.fecha_pedido, 'YYYY-MM-DD') ||
            ' | Total: ' || r_pedido.total ||
            ' | Lineas: ' || r_pedido.cantidad_lineas
        );

    END LOOP;


    CLOSE cur_pedidos_cliente;


    IF NOT vb_encontro THEN

        DBMS_OUTPUT.PUT_LINE(
            'No se encontraron pedidos confirmados para el cliente.'
        );

    END IF;

END;
/

------------------------------------------------------------------- 3.3 (3 pts)
-- Bloque anonimo con un CURSOR FOR UPDATE que recorra los productos de una
-- categoria y ajuste su precio un porcentaje dado, usando WHERE CURRENT OF.
--   * No debe modificar productos inactivos
--   * El precio resultante no puede quedar por debajo del costo mas el margen
--     minimo de la categoria
-- Explique que bloqueo genera FOR UPDATE, cuanto dura, y por que WHERE CURRENT OF
-- es preferible a un UPDATE por clave primaria.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Se utiliza un cursor FOR UPDATE para bloquear los productos activos de la
-- categoria seleccionada mientras se realiza la modificacion de sus precios.
-- El bloqueo evita que otra transaccion modifique simultaneamente esas filas y
-- permanece hasta que se realice COMMIT o ROLLBACK.
--
-- Para cada producto se calcula el nuevo precio aplicando el porcentaje indicado.
-- Adicionalmente, se calcula el precio minimo permitido utilizando el costo del
-- producto y el margen minimo definido para la categoria. Si el precio calculado
-- queda por debajo de este limite, se utiliza el precio minimo permitido.
--
-- WHERE CURRENT OF permite actualizar exactamente la fila sobre la cual se
-- encuentra posicionado el cursor, evitando realizar nuevamente una busqueda por
-- la llave primaria y manteniendo una relacion directa entre la fila leida y la
-- fila modificada.

DECLARE

    vn_id_categoria      NUMBER := 1;
    vn_porcentaje_ajuste NUMBER := 10;
    vn_margen_minimo     NUMBER;
    vn_precio_calculado  NUMBER;
    vn_precio_minimo     NUMBER;
    vn_precio_final      NUMBER;


    CURSOR cur_productos_categoria IS
        SELECT id_producto,
               codigo,
               precio_unitario,
               costo_unitario
        FROM PRODUCTO
        WHERE id_categoria = vn_id_categoria
          AND activo = 'S'
        FOR UPDATE OF precio_unitario;


    r_producto cur_productos_categoria%ROWTYPE;

BEGIN

    ---------------------------------------------------------------------------
    -- Consultar el margen minimo correspondiente a la categoria
    ---------------------------------------------------------------------------

    SELECT margen_minimo
    INTO vn_margen_minimo
    FROM CATEGORIA
    WHERE id_categoria = vn_id_categoria;


    OPEN cur_productos_categoria;


    LOOP

        FETCH cur_productos_categoria
        INTO r_producto;


        EXIT WHEN cur_productos_categoria%NOTFOUND;


        -----------------------------------------------------------------------
        -- Calcular el nuevo precio aplicando el porcentaje
        -----------------------------------------------------------------------

        vn_precio_calculado :=
            r_producto.precio_unitario *
            (1 + vn_porcentaje_ajuste / 100);


        -----------------------------------------------------------------------
        -- Calcular el menor precio permitido segun costo y margen
        -----------------------------------------------------------------------

        vn_precio_minimo :=
            r_producto.costo_unitario *
            (1 + vn_margen_minimo / 100);


        -----------------------------------------------------------------------
        -- Evitar que el precio quede por debajo del minimo permitido
        -----------------------------------------------------------------------

        IF vn_precio_calculado < vn_precio_minimo THEN

            vn_precio_final := vn_precio_minimo;

        ELSE

            vn_precio_final := vn_precio_calculado;

        END IF;


        -----------------------------------------------------------------------
        -- Actualizar exactamente la fila actual del cursor
        -----------------------------------------------------------------------

        UPDATE PRODUCTO
        SET precio_unitario = ROUND(vn_precio_final, 2)
        WHERE CURRENT OF cur_productos_categoria;


        DBMS_OUTPUT.PUT_LINE(
            'Producto: ' || r_producto.codigo ||
            ' | Precio anterior: ' || r_producto.precio_unitario ||
            ' | Precio nuevo: ' || ROUND(vn_precio_final, 2)
        );


    END LOOP;


    CLOSE cur_productos_categoria;


    ---------------------------------------------------------------------------
    -- Se confirma la transaccion y con ello se liberan los bloqueos FOR UPDATE
    ---------------------------------------------------------------------------

    COMMIT;


EXCEPTION

    WHEN NO_DATA_FOUND THEN

        IF cur_productos_categoria%ISOPEN THEN
            CLOSE cur_productos_categoria;
        END IF;

        ROLLBACK;

        RAISE_APPLICATION_ERROR(
            -20020,
            'La categoria indicada no existe'
        );


    WHEN OTHERS THEN

        IF cur_productos_categoria%ISOPEN THEN
            CLOSE cur_productos_categoria;
        END IF;

        ROLLBACK;

        RAISE;

END;
/
------------------------------------------------------------------- 3.4 (2 pts)
-- SP_LISTAR_MOVIMIENTOS
-- Procedimiento que reciba un identificador de producto y devuelva un
-- SYS_REFCURSOR con los movimientos de inventario de ese producto, ordenados
-- por fecha. Incluya un bloque anonimo que consuma el cursor devuelto y lo cierre.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- El procedimiento utiliza un SYS_REFCURSOR para devolver al llamador un
-- conjunto de registros generado dinamicamente. El cursor contiene los
-- movimientos correspondientes al producto recibido como parametro y se ordena
-- cronologicamente por fecha de movimiento. El procedimiento solamente abre el
-- cursor; el bloque que lo recibe es responsable de recorrerlo mediante FETCH y
-- cerrarlo cuando termina de utilizarlo.

CREATE OR REPLACE PROCEDURE SP_LISTAR_MOVIMIENTOS (
    param_id_producto IN  NUMBER,
    param_cursor      OUT SYS_REFCURSOR
) IS

BEGIN

    OPEN param_cursor FOR

        SELECT id_movimiento,
               id_bodega,
               tipo,
               cantidad,
               fecha_mov,
               id_pedido,
               observacion
        FROM MOVIMIENTO_INVENTARIO
        WHERE id_producto = param_id_producto
        ORDER BY fecha_mov,
                 id_movimiento;

END SP_LISTAR_MOVIMIENTOS;
/

-- Bloque consumidor:

DECLARE

    cur_movimientos SYS_REFCURSOR;

    vn_id_movimiento NUMBER;
    vn_id_bodega     NUMBER;
    vv_tipo          VARCHAR2(10);
    vn_cantidad      NUMBER;
    vd_fecha_mov     DATE;
    vn_id_pedido     NUMBER;
    vv_observacion   VARCHAR2(200);

BEGIN

    ---------------------------------------------------------------------------
    -- Solicitar el cursor para el producto 1001
    ---------------------------------------------------------------------------

    SP_LISTAR_MOVIMIENTOS(
        param_id_producto => 1001,
        param_cursor      => cur_movimientos
    );


    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE(' MOVIMIENTOS DEL PRODUCTO 1001');
    DBMS_OUTPUT.PUT_LINE('==============================================');


    LOOP

        FETCH cur_movimientos
        INTO vn_id_movimiento,
             vn_id_bodega,
             vv_tipo,
             vn_cantidad,
             vd_fecha_mov,
             vn_id_pedido,
             vv_observacion;


        EXIT WHEN cur_movimientos%NOTFOUND;


        DBMS_OUTPUT.PUT_LINE(
            'Movimiento: ' || vn_id_movimiento ||
            ' | Bodega: ' || vn_id_bodega ||
            ' | Tipo: ' || vv_tipo ||
            ' | Cantidad: ' || vn_cantidad ||
            ' | Fecha: ' || TO_CHAR(vd_fecha_mov, 'YYYY-MM-DD') ||
            ' | Pedido: ' || NVL(TO_CHAR(vn_id_pedido), 'SIN PEDIDO') ||
            ' | Observacion: ' || NVL(vv_observacion, 'SIN OBSERVACION')
        );


    END LOOP;


    ---------------------------------------------------------------------------
    -- El consumidor es responsable de cerrar el SYS_REFCURSOR
    ---------------------------------------------------------------------------

    CLOSE cur_movimientos;


EXCEPTION

    WHEN OTHERS THEN

        IF cur_movimientos%ISOPEN THEN
            CLOSE cur_movimientos;
        END IF;

        RAISE;

END;
/

------------------------------------------------------------------- 3.5 (1 pt)
-- Bloque anonimo que cargue con BULK COLLECT los productos de una categoria en
-- una coleccion y use FORALL para actualizar su stock minimo.
-- Explique que costo concreto elimina esta tecnica y a partir de que volumen
-- empieza a notarse.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- BULK COLLECT permite recuperar varias filas de SQL hacia una coleccion PL/SQL
-- en una sola operacion, mientras que FORALL permite ejecutar una operacion DML
-- sobre todos los elementos de la coleccion sin realizar un UPDATE individual
-- desde PL/SQL para cada fila.
-- Esta tecnica reduce principalmente los cambios de contexto entre el motor
-- PL/SQL y el motor SQL, que ocurririan repetidamente en un procesamiento fila
-- por fila. No existe un numero universal a partir del cual sea obligatorio usar
-- procesamiento masivo, pero la diferencia comienza a ser medible con cientos
-- de registros y suele ser mucho mas evidente cuando se procesan miles de filas.

DECLARE

    ---------------------------------------------------------------------------
    -- Tipo de coleccion para almacenar identificadores de productos
    ---------------------------------------------------------------------------

    TYPE t_ids_productos IS
        TABLE OF PRODUCTO.id_producto%TYPE;


    v_ids_productos t_ids_productos;


    vn_id_categoria      NUMBER := 1;
    vn_porcentaje_aumento NUMBER := 10;

BEGIN

    ---------------------------------------------------------------------------
    -- Cargar todos los productos de la categoria en una coleccion
    ---------------------------------------------------------------------------

    SELECT id_producto
    BULK COLLECT INTO v_ids_productos
    FROM PRODUCTO
    WHERE id_categoria = vn_id_categoria;


    ---------------------------------------------------------------------------
    -- Actualizar masivamente el stock minimo
    ---------------------------------------------------------------------------

    IF v_ids_productos.COUNT > 0 THEN

        FORALL vn_indice IN 1 .. v_ids_productos.COUNT

            UPDATE PRODUCTO
            SET stock_minimo =
                CEIL(
                    stock_minimo *
                    (1 + vn_porcentaje_aumento / 100)
                )
            WHERE id_producto = v_ids_productos(vn_indice);


        DBMS_OUTPUT.PUT_LINE(
            'Productos actualizados: ' || SQL%ROWCOUNT
        );


        COMMIT;


    ELSE

        DBMS_OUTPUT.PUT_LINE(
            'No existen productos para la categoria indicada'
        );

    END IF;


EXCEPTION

    WHEN OTHERS THEN

        ROLLBACK;

        RAISE;

END;
/
--==============================================================================
-- PARTE 4 — MANEJO DE EXCEPCIONES                             (9 puntos / 75 min)
--==============================================================================

------------------------------------------------------------------- 4.1 (2 pts)
-- FN_PRECIO_PRODUCTO
-- Funcion que reciba el CODIGO de un producto y retorne su precio, manejando
-- explicitamente NO_DATA_FOUND y TOO_MANY_ROWS, con retorno de -1 y -2
-- respectivamente, e imprimiendo un mensaje descriptivo en cada caso.
-- Explique en que situacion real se produciria TOO_MANY_ROWS sobre esta tabla,
-- considerando las restricciones que hoy tiene.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Considerando la estructura actual del esquema (script 01), la tabla PRODUCTO 
-- tiene una restriccion UNIQUE sobre la columna 'codigo' (uk_producto_codigo). 
-- Por lo tanto, bajo condiciones normales, la excepcion TOO_MANY_ROWS jamas 
-- se dispararia. La unica situacion real en la que este error ocurriria es 
-- si un administrador de base de datos (DBA) deshabilita o elimina la 
-- restriccion UNIQUE temporalmente y se insertan registros duplicados, o si el 
-- motor sufre una corrupcion de indices que devuelva mas de un ROWID para un 
-- solo codigo en el bloque de ejecucion.
CREATE OR REPLACE FUNCTION FN_PRECIO_PRODUCTO (
    param_codigo IN VARCHAR2
) RETURN NUMBER IS
    vn_precio NUMBER;
BEGIN
    SELECT precio_unitario
    INTO vn_precio
    FROM PRODUCTO
    WHERE codigo = param_codigo;

    RETURN vn_precio;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: El producto con codigo ' || param_codigo || ' no fue encontrado.');
        RETURN -1;
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error: Se encontraron multiples registros para el codigo ' || param_codigo || '.');
        RETURN -2;
END FN_PRECIO_PRODUCTO;
/

------------------------------------------------------------------- 4.2 (2 pts)
-- SP_VALIDAR_DESPACHO
-- Procedimiento que verifique si puede despacharse una cantidad de un producto
-- desde una bodega. Debe declarar una EXCEPCION PROPIA, levantarla con RAISE
-- cuando la cantidad solicitada supere el disponible, y capturarla en el bloque
-- EXCEPTION.
-- Argumente por que conviene nombrar esa condicion en lugar de resolverla con un
-- condicional.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Nombrar la condicion como una excepcion propia (e_stock_insuficiente) permite 
-- separar la logica del "camino feliz" (happy path) del manejo de errores de 
-- negocio. Si usaramos un simple IF/ELSE, el codigo se anidaria volviendose 
-- dificil de mantener. Al usar RAISE, centralizamos la gestion del error en el 
-- bloque EXCEPTION, facilitando el registro (logging) y permitiendo que, si 
-- este procedimiento es llamado por otro paquete, el error pueda propagarse de  
-- forma estructurada hacia la capa superior de la aplicacion.
CREATE OR REPLACE PROCEDURE SP_VALIDAR_DESPACHO (
    param_id_producto IN NUMBER,
    param_id_bodega   IN NUMBER,
    param_cantidad    IN NUMBER
) IS
    vn_disponible NUMBER;
    e_stock_insuficiente EXCEPTION;
BEGIN
    -- Obtenemos el disponible (usamos NVL por si no existe la relacion en la bodega)
    SELECT NVL(SUM(cantidad), 0)
    INTO vn_disponible
    FROM EXISTENCIA
    WHERE id_producto = param_id_producto
      AND id_bodega = param_id_bodega;

    IF param_cantidad > vn_disponible THEN
        RAISE e_stock_insuficiente;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Validacion exitosa: Hay stock suficiente para el despacho.');
EXCEPTION
    WHEN e_stock_insuficiente THEN
        DBMS_OUTPUT.PUT_LINE('Error de Negocio: La cantidad requerida (' || param_cantidad || 
                             ') supera el inventario disponible (' || vn_disponible || ').');
END SP_VALIDAR_DESPACHO;
/

------------------------------------------------------------------- 4.3 (2 pts)
-- SP_ANULAR_PEDIDO
-- Procedimiento que anule un pedido, usando RAISE_APPLICATION_ERROR con estos
-- codigos:
--     -20010  el pedido no existe
--     -20011  el pedido ya esta anulado
--     -20012  el pedido tiene mas de 30 dias
-- Explique la diferencia entre RAISE y RAISE_APPLICATION_ERROR, y en que caso el
-- cliente de la base de datos puede distinguirlos.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- La diferencia principal es el alcance y la comunicacion con el exterior. RAISE 
-- levanta una excepcion interna que, si no se maneja en un bloque EXCEPTION de 
-- PL/SQL, lanzara un error generico. Por otro lado, RAISE_APPLICATION_ERROR 
-- permite asignar un codigo personalizado (rango -20000 a -20999) y un mensaje 
-- que viajan directamente hasta el cliente de la base de datos (por ejemplo, 
-- una API en Java o C#). El cliente exterior puede atrapar ese codigo numerico 
-- exacto e informar al usuario final (ej: "Pedido vencido") en lugar de mostrar 
-- un mensaje nativo incomprensible de Oracle.
CREATE OR REPLACE PROCEDURE SP_ANULAR_PEDIDO (
    param_id_pedido IN NUMBER
) IS
    vv_estado       PEDIDO.estado%TYPE;
    vd_fecha_pedido PEDIDO.fecha_pedido%TYPE;
BEGIN
    SELECT estado, fecha_pedido
    INTO vv_estado, vd_fecha_pedido
    FROM PEDIDO
    WHERE id_pedido = param_id_pedido;

    IF vv_estado = 'ANULADO' THEN
        RAISE_APPLICATION_ERROR(-20011, 'El pedido ya esta anulado.');
    ELSIF (SYSDATE - vd_fecha_pedido) > 30 THEN
        RAISE_APPLICATION_ERROR(-20012, 'El pedido tiene mas de 30 dias y no puede anularse.');
    END IF;

    UPDATE PEDIDO
    SET estado = 'ANULADO'
    WHERE id_pedido = param_id_pedido;

    DBMS_OUTPUT.PUT_LINE('El pedido ' || param_id_pedido || ' ha sido anulado.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'El pedido especificado no existe.');
END SP_ANULAR_PEDIDO;
/

------------------------------------------------------------------- 4.4 (2 pts)
-- Bloque anonimo que intente insertar un producto con una categoria inexistente
-- y capture el error de integridad referencial asociando ORA-02291 a una
-- excepcion con nombre.
-- Explique que aporta esa asociacion frente a atrapar el error en un manejador
-- generico.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Atrapando el error con PRAGMA EXCEPTION_INIT vinculamos el codigo interno de 
-- Oracle (ORA-02291: violation of foreign key) a un nombre semantico claro 
-- (e_integridad_referencial). Si usaramos un manejador generico (WHEN OTHERS), 
-- estariamos atrapando TODOS los errores ciegamente, ocultando posibles fallas 
-- criticas de base de datos (como falta de espacio, red caida o tabla corrupta), 
-- convirtiendo la depuracion en una pesadilla al enmascarar la verdadera causa 
-- del fallo. La excepcion nombrada asegura que reaccionemos SOLO a ese error.
DECLARE
    e_integridad_referencial EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_integridad_referencial, -2291);
BEGIN
    -- Intentamos insertar un producto atado a la categoria 999 (que no existe)
    INSERT INTO PRODUCTO (id_producto, codigo, nombre, id_categoria, precio_unitario, costo_unitario)
    VALUES (SEQ_PRODUCTO.NEXTVAL, 'ERR-01', 'Prueba Error FK', 999, 1000, 500);
    
    DBMS_OUTPUT.PUT_LINE('Exito inesperado: El registro fue insertado.');
EXCEPTION
    WHEN e_integridad_referencial THEN
        DBMS_OUTPUT.PUT_LINE('Fallo controlado: No se puede insertar el producto porque la categoria no existe (Violacion FK).');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ocurrio un error no contemplado: ' || SQLERRM);
END;
/

------------------------------------------------------------------- 4.5 (1 pt)
-- SP_REGISTRAR_ERROR
-- Procedimiento que reciba el origen y registre en LOG_ERRORES el SQLCODE y el
-- SQLERRM actuales. El registro debe persistir aunque la transaccion principal
-- termine en ROLLBACK.
-- Explique por que se requiere esa independencia transaccional y describa un
-- escenario en el que esa misma independencia oculte informacion en lugar de
-- preservarla.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
-- Se requiere PRAGMA AUTONOMOUS_TRANSACTION para aislar la transaccion del 
-- LOG de la transaccion de negocio principal. Si una venta falla, debemos hacer 
-- ROLLBACK de los inventarios y recibos, pero si no la aislaramos, el ROLLBACK 
-- tambien borraria la evidencia del log recien insertada. Un escenario donde 
-- esto oculte informacion es si el procedimiento autonomo modifica datos de 
-- negocio en vez de tablas de log; los cambios quedarian persistidos mientras 
-- el proceso padre falla, rompiendo la atomicidad (ACID) y dejando la base de 
-- datos en un estado de inconsistencia imperceptible.
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_ERROR (
    param_origen  IN VARCHAR2,
    param_detalle IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    vn_codigo_error NUMBER        := SQLCODE;
    vv_mensaje      VARCHAR2(500) := SUBSTR(SQLERRM, 1, 500);
BEGIN
    INSERT INTO LOG_ERRORES (id_log, origen, codigo_error, mensaje, detalle)
    VALUES (SEQ_LOG.NEXTVAL, param_origen, vn_codigo_error, vv_mensaje, param_detalle);
    
    -- Este COMMIT solo afecta a LOG_ERRORES, no al proceso que llamo al SP.
    COMMIT; 
END SP_REGISTRAR_ERROR;
/

--==============================================================================
-- PARTE 5 — DISPARADORES                                     (10 puntos / 90 min)
--==============================================================================
-- Los esqueletos de esta parte no incluyen la clausula de disparo. Definirla
-- hace parte del ejercicio.
--==============================================================================

------------------------------------------------------------------- 5.1 (2 pts)
-- TRG_CLIENTE_BI
-- Al insertar un cliente debe asignar el identificador desde SEQ_CLIENTE si
-- llega nulo, convertir el nombre a mayusculas sin espacios sobrantes y forzar
-- el estado activo a 'S' si no se indica.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- * BEFORE INSERT FOR EACH ROW: es el unico momento en que :NEW es modificable.
--   En un AFTER, asignar a :NEW produce ORA-04084; ademas, un AFTER llegaria
--   tarde: las restricciones NOT NULL de id_cliente y activo ya se habrian
--   evaluado y la fila habria sido rechazada antes de poder corregirla.
--   Debe ser de fila (FOR EACH ROW) porque trabaja sobre los valores de cada
--   fila; un disparador de sentencia no tiene acceso a :NEW.
-- * El identificador solo se toma de la secuencia cuando llega nulo, asi se
--   respetan los ids que el usuario o una migracion indiquen de forma explicita.
--   Los huecos en la secuencia (por ROLLBACK) son normales y no son un error.
-- * Nombre: UPPER(TRIM(...)) quita espacios al inicio y al final; REGEXP_REPLACE
--   colapsa los espacios repetidos internos a uno solo (interpretacion de
--   "espacios sobrantes"). Hacerlo en el disparador garantiza la regla sin
--   importar desde que aplicacion o herramienta se inserte.
-- * Estado activo: el DEFAULT 'S' de la columna solo se aplica cuando la
--   columna se omite del INSERT; si llega un NULL explicito, el DEFAULT no
--   actua. El IF del disparador cubre ese caso.
-- * Analisis operacional: SEQ_CLIENTE arranca en 500 y el script 01 NO la
--   sincronizo con los clientes cargados (501 a 507). Por eso el primer id
--   generado (500) funciona, pero el segundo (501) choca con la PK (ORA-00001).
--   Antes de usar el disparador hay que avanzar la secuencia (ver archivo de
--   pruebas). Solo actua en INSERT: un UPDATE posterior del nombre no se
--   normaliza, porque el enunciado solo lo pide al insertar.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_CLIENTE_BI
BEFORE INSERT ON CLIENTE
FOR EACH ROW
BEGIN
    IF :NEW.id_cliente IS NULL THEN
        :NEW.id_cliente := SEQ_CLIENTE.NEXTVAL;
    END IF;

    :NEW.nombre := UPPER(TRIM(REGEXP_REPLACE(:NEW.nombre, '\s{2,}', ' ')));

    IF :NEW.activo IS NULL THEN
        :NEW.activo := 'S';
    END IF;
END TRG_CLIENTE_BI;
/

------------------------------------------------------------------- 5.2 (2 pts)
-- TRG_PRODUCTO_AU_PRECIO
-- Debe registrar en AUDITORIA_PRECIO todo cambio de precio, calculando la
-- variacion porcentual, y dispararse unicamente cuando el precio efectivamente
-- cambie, resolviendo esa condicion con la clausula WHEN y no dentro del cuerpo.
-- Explique la diferencia entre ambas formas.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- * AFTER UPDATE: la auditoria debe registrar solo cambios que ya fueron
--   aceptados por las validaciones (TRG_PRODUCTO_BIU_MARGEN y las restricciones
--   CHECK). Con un BEFORE se auditaria un precio que todavia puede ser
--   rechazado, y el resultado dependeria del orden entre disparadores.
-- * UPDATE OF precio_unitario: el disparador ni se evalua cuando la sentencia
--   no menciona esa columna (por ejemplo, un UPDATE de stock_minimo).
--   Pero UPDATE OF se activa aunque el valor quede igual ("SET precio = precio"),
--   por eso ademas se necesita el WHEN.
-- * Diferencia WHEN vs IF en el cuerpo:
--     - WHEN lo evalua el motor ANTES de invocar el bloque PL/SQL. Si es falso,
--       el cuerpo nunca se ejecuta: no hay cambio de contexto SQL -> PL/SQL ni
--       costo de ejecutar el disparador. Con IF en el cuerpo, el disparador se
--       ejecuta por cada fila afectada y recien adentro se descarta; en una
--       actualizacion masiva (p. ej. el cursor 3.3) la diferencia es medible.
--     - WHEN es declarativo: la condicion queda visible en el encabezado y en
--       USER_TRIGGERS.WHEN_CLAUSE, sin leer el cuerpo.
--     - Limites del WHEN: solo aplica a disparadores de fila, acepta una
--       expresion SQL (sin subconsultas) y en ella NEW/OLD se escriben sin ':'.
-- * Comparacion con <>: precio_unitario es NOT NULL, asi que <> no pierde
--   cambios por NULL. Si la columna admitiera NULL habria que usar LNNVL o NVL.
-- * variacion_pct = (nuevo - anterior) / anterior * 100, con 2 decimales. No hay
--   division por cero porque CK_PRODUCTO_PRECIO obliga a precio > 0.
-- * usuario_bd y fecha_cambio se llenan por DEFAULT de la tabla.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PRODUCTO_AU_PRECIO
AFTER UPDATE OF precio_unitario ON PRODUCTO
FOR EACH ROW
WHEN (NEW.precio_unitario <> OLD.precio_unitario)
BEGIN
    INSERT INTO AUDITORIA_PRECIO
        (id_auditoria, id_producto, precio_anterior, precio_nuevo, variacion_pct)
    VALUES
        (SEQ_AUDITORIA.NEXTVAL,
         :NEW.id_producto,
         :OLD.precio_unitario,
         :NEW.precio_unitario,
         ROUND((:NEW.precio_unitario - :OLD.precio_unitario)
               / :OLD.precio_unitario * 100, 2));
END TRG_PRODUCTO_AU_PRECIO;
/

------------------------------------------------------------------- 5.3 (2 pts)
-- TRG_PRODUCTO_BIU_MARGEN
-- Debe impedir que se guarde un producto cuyo precio no alcance el margen minimo
-- de su categoria, segun la formula precio >= costo * (1 + margen/100),
-- rechazando la operacion con el error -20020.
-- Considere que debe ocurrir cuando la categoria indicada no existe, y justifique
-- su decision.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- * BEFORE: es una validacion; debe rechazar antes de escribir la fila.
-- * INSERT OR UPDATE OF precio_unitario, costo_unitario, id_categoria: la regla
--   depende solo de esas tres columnas. Un UPDATE que toque otras (stock_minimo,
--   activo, nombre) no puede romperla, asi que no se paga la consulta a CATEGORIA.
-- * Se consulta CATEGORIA (otra tabla), no PRODUCTO, por lo que no hay error de
--   tabla mutante.
-- * La comparacion usa NUMBER, que es decimal exacto: el limite es inclusivo
--   (precio = costo * (1 + margen/100) se acepta) y no hay errores de redondeo
--   binario como los habria con FLOAT.
-- * DECISION cuando la categoria no existe: el disparador NO levanta error
--   propio y deja pasar la fila; quien la rechaza es la llave foranea
--   FK_PRODUCTO_CATEGORIA con ORA-02291. Razones: (1) la integridad referencial
--   ya es responsabilidad de la FK, y duplicarla en el disparador crearia dos
--   mensajes distintos para el mismo problema; (2) un -20020 aqui diria
--   "margen insuficiente", que seria un diagnostico falso; (3) el ejercicio 4.4
--   necesita precisamente que el INSERT con categoria inexistente llegue a la
--   FK para capturar ORA-02291 con PRAGMA EXCEPTION_INIT; si el disparador
--   lanzara su propio error, el 4.4 jamas veria el ORA-02291.
-- * Limite conocido: si luego cambia CATEGORIA.margen_minimo, los productos ya
--   guardados no se revalidan; la regla se aplica cuando el producto se toca.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PRODUCTO_BIU_MARGEN
BEFORE INSERT OR UPDATE OF precio_unitario, costo_unitario, id_categoria ON PRODUCTO
FOR EACH ROW
DECLARE
    vn_margen  CATEGORIA.margen_minimo%TYPE;
    vn_minimo  NUMBER;
BEGIN
    SELECT margen_minimo
      INTO vn_margen
      FROM CATEGORIA
     WHERE id_categoria = :NEW.id_categoria;

    vn_minimo := :NEW.costo_unitario * (1 + vn_margen / 100);

    IF :NEW.precio_unitario < vn_minimo THEN
        RAISE_APPLICATION_ERROR(-20020,
            'Precio ' || :NEW.precio_unitario || ' inferior al minimo permitido '
            || ROUND(vn_minimo, 2) || ' (costo ' || :NEW.costo_unitario
            || ' con margen minimo de ' || vn_margen || '% de la categoria '
            || :NEW.id_categoria || ')');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;  -- categoria inexistente: la rechaza la FK con ORA-02291
END TRG_PRODUCTO_BIU_MARGEN;
/

------------------------------------------------------------------- 5.4 (2 pts)
-- TRG_DETALLE_AI_STOCK
-- Al insertar una linea de pedido debe descontar el stock de la bodega indicada
-- y registrar el movimiento de SALIDA correspondiente. Si no hay stock suficiente
-- debe abortar la operacion con el error -20030.
-- Explique por que el momento de disparo que eligio es el correcto y que dejaria
-- de funcionar con el contrario.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- * AFTER INSERT FOR EACH ROW. Segun el orden de disparo de Oracle, por cada
--   fila: (1) BEFORE ROW, (2) se inserta la fila y se verifican PK, FK y CHECK,
--   (3) AFTER ROW. Con AFTER, el descuento de stock solo corre para una linea
--   que ya es valida y forma parte de la tabla. No se modifica :NEW, asi que no
--   se necesita un BEFORE.
-- * Que dejaria de funcionar con BEFORE: el disparador actuaria sobre una fila
--   que aun no paso las restricciones. Ejemplo: una linea con cantidad negativa
--   (que CK_DETALLE_CANTIDAD rechazaria despues) haria que el UPDATE SUMARA
--   stock antes de ser rechazada; una linea duplicada en la PK tambien
--   descontaria antes de fallar. Ademas, en BEFORE la linea no existe todavia en
--   DETALLE_PEDIDO, asi que cualquier consulta que la necesite no la veria.
--   (La atomicidad no es la diferencia: si la sentencia falla, Oracle deshace
--   tambien lo que hizo el disparador en ambos casos.)
-- * Verificar y descontar en UNA sola sentencia:
--     UPDATE ... SET cantidad = cantidad - :NEW.cantidad ... AND cantidad >= :NEW.cantidad
--   Un SELECT previo seguido de un UPDATE deja una ventana de concurrencia
--   (dos sesiones leen 10, ambas descuentan 8 y el saldo queda en -6). Con la
--   condicion dentro del UPDATE, la fila se bloquea y la segunda sesion espera
--   y reevalua la condicion con el saldo ya descontado. CK_EXISTENCIA_CANTIDAD
--   queda como ultima barrera.
-- * SQL%ROWCOUNT = 0 cubre dos causas: que la combinacion bodega-producto no
--   exista o que el saldo sea menor. Ambas se rechazan con -20030; el mensaje
--   informa el disponible para diferenciarlas.
-- * No se invoca SP_AJUSTAR_STOCK para no acoplar este disparador a la firma de
--   un objeto de otra parte y porque debe abortar con el codigo especifico -20030.
-- * Analisis operacional: solo actua en INSERT, como pide el enunciado. Un
--   UPDATE de cantidad o un DELETE de la linea NO devuelven ni descuentan stock;
--   en produccion se requeriria cubrir esos casos (o prohibirlos).
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_DETALLE_AI_STOCK
AFTER INSERT ON DETALLE_PEDIDO
FOR EACH ROW
DECLARE
    vn_disponible EXISTENCIA.cantidad%TYPE;
BEGIN
    UPDATE EXISTENCIA
       SET cantidad = cantidad - :NEW.cantidad
     WHERE id_bodega   = :NEW.id_bodega
       AND id_producto = :NEW.id_producto
       AND cantidad   >= :NEW.cantidad;

    IF SQL%ROWCOUNT = 0 THEN
        BEGIN
            SELECT cantidad
              INTO vn_disponible
              FROM EXISTENCIA
             WHERE id_bodega   = :NEW.id_bodega
               AND id_producto = :NEW.id_producto;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                vn_disponible := 0;
        END;

        RAISE_APPLICATION_ERROR(-20030,
            'Stock insuficiente: producto ' || :NEW.id_producto || ' en bodega '
            || :NEW.id_bodega || ' (solicitado ' || :NEW.cantidad
            || ', disponible ' || vn_disponible || ')');
    END IF;

    INSERT INTO MOVIMIENTO_INVENTARIO
        (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov,
         id_pedido, observacion)
    VALUES
        (SEQ_MOVIMIENTO.NEXTVAL, :NEW.id_producto, :NEW.id_bodega, 'SALIDA',
         :NEW.cantidad, SYSDATE, :NEW.id_pedido,
         'Despacho de pedido ' || :NEW.id_pedido || ' linea ' || :NEW.linea);
END TRG_DETALLE_AI_STOCK;
/

------------------------------------------------------------------- 5.5 (1 pt)
-- TRG_DETALLE_TOTAL
-- Debe recalcular el total de la cabecera del pedido despues de cualquier
-- insercion, actualizacion o borrado de sus lineas.
-- Documente el error que obtiene en su primer intento, en que momento aparece,
-- y como lo resuelve la construccion que finalmente utilizo.
-- Este punto no se califica sin esa explicacion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- PRIMER INTENTO (disparador de fila que suma las lineas del pedido):
--
--   CREATE OR REPLACE TRIGGER TRG_DETALLE_TOTAL_V1
--   AFTER INSERT OR UPDATE OR DELETE ON DETALLE_PEDIDO
--   FOR EACH ROW
--   BEGIN
--       UPDATE PEDIDO
--          SET total = (SELECT NVL(SUM(subtotal), 0) FROM DETALLE_PEDIDO
--                        WHERE id_pedido = NVL(:NEW.id_pedido, :OLD.id_pedido))
--        WHERE id_pedido = NVL(:NEW.id_pedido, :OLD.id_pedido);
--   END;
--
-- ERROR: ORA-04091: table <ESQUEMA>.DETALLE_PEDIDO is mutating, trigger/function
--        may not see it   (seguido de ORA-06512 y ORA-04088).
--   >>> GRUPO: reproduzcan este intento y peguen aqui la salida REAL. <<<
--   >>> Usen un UPDATE o DELETE de una linea, o un INSERT ... SELECT de varias
--   >>> filas; un INSERT ... VALUES de una sola fila no siempre lo dispara.
--
-- CUANDO APARECE: en TIEMPO DE EJECUCION, al disparar la primera fila de la
--   sentencia DML; NO al crear el disparador (CREATE TRIGGER compila sin error,
--   porque el compilador no puede saber que tabla estara en modificacion).
--
-- QUE ES LA TABLA MUTANTE: una tabla esta "mutando" mientras la sentencia que
--   disparo el trigger de fila la esta modificando. En ese instante algunas filas
--   ya cambiaron y otras no, y el resultado de un SELECT sobre ella dependeria
--   del orden en que Oracle procese las filas. Para evitar resultados
--   indeterminados, Oracle prohibe que un disparador de FILA lea o modifique la
--   tabla de su propia sentencia (ORA-04091). Aqui la causa es que el disparador
--   de fila consulta DETALLE_PEDIDO (SUM) mientras DETALLE_PEDIDO esta mutando.
--
-- COMO LO RESUELVE EL COMPOUND TRIGGER:
--   - AFTER EACH ROW: no consulta ninguna tabla; solo anota en una coleccion
--     (variable de la seccion declarativa, compartida por todas las secciones)
--     el id de cada pedido afectado. Sin acceso a DETALLE_PEDIDO, no hay ORA-04091.
--   - AFTER STATEMENT: corre UNA vez, cuando la sentencia ya termino de modificar
--     la tabla y esta ya no esta mutando; ahi si se puede hacer el SUM.
--   - La coleccion usa el id como indice, asi que un pedido con muchas lineas
--     afectadas se recalcula una sola vez, no una por fila.
--   - El estado de la coleccion vive solo durante la sentencia y Oracle lo libera
--     al terminar, por lo que no hay que limpiarlo entre sentencias. Con dos
--     disparadores separados y variables de paquete habria que hacerlo a mano.
--
-- DETALLES DE DISENO:
--   - En UPDATE se anotan :OLD.id_pedido y :NEW.id_pedido por si la linea cambia
--     de pedido (se recalculan ambas cabeceras); en DELETE solo existe :OLD.
--   - Antes de sumar se bloquea la cabecera con SELECT ... FOR UPDATE. Si dos
--     sesiones modifican lineas del mismo pedido, la segunda espera y su SUM se
--     ejecuta despues de que la primera confirmo, asi ve sus lineas y el total
--     no queda desactualizado por concurrencia.
--   - total = SUM(subtotal): el total de la cabecera es bruto (asi estan los
--     datos cargados). Si la Parte 6 guarda un total con descuento, cualquier
--     cambio posterior de lineas lo reemplaza por el bruto.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_DETALLE_TOTAL
FOR INSERT OR UPDATE OR DELETE ON DETALLE_PEDIDO
COMPOUND TRIGGER

    -- Conjunto de pedidos afectados por la sentencia (indice = id del pedido)
    TYPE t_pedidos IS TABLE OF BOOLEAN INDEX BY VARCHAR2(12);
    vt_pedidos  t_pedidos;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING OR UPDATING THEN
            vt_pedidos(TO_CHAR(:NEW.id_pedido)) := TRUE;
        END IF;
        IF DELETING OR UPDATING THEN
            vt_pedidos(TO_CHAR(:OLD.id_pedido)) := TRUE;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        vv_clave  VARCHAR2(12);
        vn_id     PEDIDO.id_pedido%TYPE;
        vn_bloq   PEDIDO.id_pedido%TYPE;
    BEGIN
        vv_clave := vt_pedidos.FIRST;
        WHILE vv_clave IS NOT NULL LOOP
            vn_id := TO_NUMBER(vv_clave);
            BEGIN
                SELECT id_pedido INTO vn_bloq
                  FROM PEDIDO
                 WHERE id_pedido = vn_id
                   FOR UPDATE;

                UPDATE PEDIDO
                   SET total = (SELECT NVL(SUM(subtotal), 0)
                                  FROM DETALLE_PEDIDO
                                 WHERE id_pedido = vn_id)
                 WHERE id_pedido = vn_id;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;  -- la cabecera ya no existe: nada que recalcular
            END;
            vv_clave := vt_pedidos.NEXT(vv_clave);
        END LOOP;
    END AFTER STATEMENT;

END TRG_DETALLE_TOTAL;
/

------------------------------------------------------------------- 5.6 (1 pt)
-- TRG_V_STOCK_IO
-- Debe permitir actualizar el precio y el stock minimo del producto a traves de
-- la vista V_STOCK_CONSOLIDADO.
-- Explique por que esa vista no es actualizable de forma directa.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- * POR QUE NO ES ACTUALIZABLE: la vista contiene GROUP BY y la funcion de
--   agregacion SUM, ademas de un JOIN con un LEFT JOIN. Una fila de la vista
--   resume varias filas de EXISTENCIA (stock_total es un valor calculado, no
--   almacenado) y Oracle no puede traducir un UPDATE sobre ella a cambios
--   sobre filas concretas de las tablas base (no hay tabla "key-preserved").
--   Por eso el UPDATE directo falla con ORA-01732 (operacion DML no valida en
--   esta vista).
-- * INSTEAD OF: es el unico tipo de disparador para vistas; reemplaza la
--   operacion, y por definicion es de fila. Con el, la sentencia UPDATE sobre
--   la vista "se ejecuta" como el codigo del disparador, que la dirige a
--   PRODUCTO usando id_producto como clave.
-- * Solo se propagan precio_unitario y stock_minimo, que son columnas reales de
--   PRODUCTO. Si la sentencia intenta cambiar otra columna de la vista
--   (codigo, producto, categoria, stock_total, id_producto) se rechaza con
--   -20040; ignorarla en silencio haria que Oracle informara "1 fila
--   actualizada" sin haber cambiado nada, que es peor que un error.
-- * El UPDATE hacia PRODUCTO sigue pasando por los demas disparadores:
--   TRG_PRODUCTO_BIU_MARGEN valida el margen y TRG_PRODUCTO_AU_PRECIO audita el
--   cambio de precio. El disparador de la vista no duplica esas reglas.
-- * Analisis operacional: cada fila de la vista afectada genera un UPDATE sobre
--   PRODUCTO; una actualizacion masiva por la vista es por tanto fila a fila.
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_V_STOCK_IO
INSTEAD OF UPDATE ON V_STOCK_CONSOLIDADO
FOR EACH ROW
BEGIN
    IF :NEW.id_producto <> :OLD.id_producto
       OR :NEW.codigo    <> :OLD.codigo
       OR :NEW.producto  <> :OLD.producto
       OR :NEW.categoria <> :OLD.categoria
       OR :NEW.stock_total <> :OLD.stock_total THEN
        RAISE_APPLICATION_ERROR(-20040,
            'Solo se pueden modificar precio_unitario y stock_minimo a traves de V_STOCK_CONSOLIDADO');
    END IF;

    UPDATE PRODUCTO
       SET precio_unitario = :NEW.precio_unitario,
           stock_minimo    = :NEW.stock_minimo
     WHERE id_producto = :OLD.id_producto;
END TRG_V_STOCK_IO;
/

--==============================================================================
-- PARTE 6 — CASO INTEGRADOR                                   (5 puntos / 45 min)
--==============================================================================

-------------------------------------------------------------------------------
-- PKG_VENTAS
-- Construya un PAQUETE que exponga el procedimiento SP_FACTURAR_PEDIDO, el cual,
-- para un pedido en estado BORRADOR, debe:
--
--   1. Validar que el pedido exista y este en BORRADOR
--   2. Recorrer sus lineas con un cursor y acumular el subtotal
--   3. Calcular el descuento con FN_CALCULAR_DESCUENTO
--   4. Validar contra FN_CUPO_DISPONIBLE que el cliente tenga cupo suficiente
--   5. Actualizar el total del pedido y cambiar su estado a CONFIRMADO
--   6. Incrementar el saldo pendiente del cliente
--   7. Usar SAVEPOINT y revertir parcialmente ante cualquier fallo, registrando
--      el error con SP_REGISTRAR_ERROR
--   8. Devolver por parametros OUT el total facturado y el descuento aplicado
--
-- Firma esperada:
--   PKG_VENTAS.SP_FACTURAR_PEDIDO(p_id_pedido IN NUMBER,
--                                 p_total     OUT NUMBER,
--                                 p_descuento OUT NUMBER)
--
-- Se evalua la integracion. El procedimiento debe apoyarse en los objetos de las
-- partes 1 a 5 y no reimplementar su logica: uno que vuelva a codificar el
-- calculo del descuento pierde la mitad del puntaje de esta parte.
-- Defina explicitamente el alcance transaccional y justifique donde decidio
-- ubicar la confirmacion de la transaccion.
-------------------------------------------------------------------------------
-- JUSTIFICACION:
--
-- * ALCANCE TRANSACCIONAL. El paquete NO hace COMMIT. La transaccion la abre y
--   la cierra quien llama, por tres razones: (1) facturar suele ser un paso de
--   una operacion mayor (crear el pedido, agregar lineas, facturar) que el
--   llamador debe poder confirmar o descartar completa; un COMMIT interno
--   confirmaria tambien trabajo previo del llamador que aun no esta validado;
--   (2) lo unico que el paquete revierte por su cuenta es lo que hizo el mismo,
--   con ROLLBACK TO SAVEPOINT, que deja intacto lo anterior de la transaccion
--   del llamador; (3) el llamador conoce el contexto (un lote de pedidos, una
--   aplicacion) y decide el COMMIT despues de recibir los parametros OUT.
-- * SAVEPOINT + manejador unico. Todas las fallas salen como
--   RAISE_APPLICATION_ERROR (-20050 a -20053, fuera de los codigos usados en
--   las partes 1 a 5). Un solo WHEN OTHERS revierte al savepoint, registra el
--   error y relanza con RAISE (la misma excepcion, con su codigo original).
--   Se usa RAISE_APPLICATION_ERROR y no excepciones declaradas porque una
--   excepcion declarada sin EXCEPTION_INIT tiene SQLCODE = 1 y SQLERRM =
--   'User-Defined Exception': SP_REGISTRAR_ERROR (que registra SQLCODE y
--   SQLERRM actuales, como pide el punto 4.5) perderia la causa real.
-- * Registro del error. SP_REGISTRAR_ERROR es autonoma: se invoca despues del
--   ROLLBACK TO y su COMMIT confirma solo el registro, que sobrevive aunque el
--   llamador termine con ROLLBACK total.
-- * Integracion. No reimplementa reglas: el descuento sale de
--   FN_CALCULAR_DESCUENTO, el cupo de FN_CUPO_DISPONIBLE y el error de
--   SP_REGISTRAR_ERROR. El UPDATE de PEDIDO no toca DETALLE_PEDIDO, por lo que
--   TRG_DETALLE_TOTAL (que recalcula el total bruto al cambiar lineas) no se
--   dispara y el total neto queda guardado.
-- * Concurrencia. SELECT ... FOR UPDATE sobre el pedido impide que dos sesiones
--   lo facturen a la vez (doble cargo al saldo). Tambien se bloquea la fila del
--   cliente ANTES de calcular descuento y cupo: ambos dependen del saldo
--   pendiente, y sin ese bloqueo dos pedidos distintos del mismo cliente,
--   facturados al tiempo, pasarian la validacion de cupo con el mismo saldo y
--   podrian excederlo.
-- * Parametros OUT. Si ocurre un error, Oracle no devuelve los valores OUT al
--   llamador (la excepcion los descarta).

CREATE OR REPLACE PACKAGE PKG_VENTAS IS

    PROCEDURE SP_FACTURAR_PEDIDO (
        param_id_pedido IN  NUMBER,
        param_total     OUT NUMBER,
        param_descuento OUT NUMBER
    );

END PKG_VENTAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_VENTAS IS

    PROCEDURE SP_FACTURAR_PEDIDO (
        param_id_pedido IN  NUMBER,
        param_total     OUT NUMBER,
        param_descuento OUT NUMBER
    ) IS
        vn_id_cliente       PEDIDO.id_cliente%TYPE;
        vv_estado           PEDIDO.estado%TYPE;
        vn_bloqueo_cliente  CLIENTE.id_cliente%TYPE;
        vn_subtotal         NUMBER := 0;
        vn_cupo_disponible  NUMBER;

        CURSOR cur_detalle_pedido IS
            SELECT subtotal
              FROM DETALLE_PEDIDO
             WHERE id_pedido = param_id_pedido;
    BEGIN
        -- Todo lo hecho desde aqui puede revertirse sin afectar al llamador
        SAVEPOINT sp_inicio_facturacion;

        -- 1. El pedido debe existir y estar en BORRADOR (queda bloqueado)
        BEGIN
            SELECT id_cliente, estado
              INTO vn_id_cliente, vv_estado
              FROM PEDIDO
             WHERE id_pedido = param_id_pedido
               FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20050, 'El pedido indicado no existe');
        END;

        IF vv_estado <> 'BORRADOR' THEN
            RAISE_APPLICATION_ERROR(-20051, 'El pedido no se encuentra en estado BORRADOR');
        END IF;

        -- 2. Recorrer las lineas y acumular el subtotal
        FOR r_detalle IN cur_detalle_pedido LOOP
            vn_subtotal := vn_subtotal + r_detalle.subtotal;
        END LOOP;

        IF vn_subtotal = 0 THEN
            RAISE_APPLICATION_ERROR(-20052, 'El pedido no contiene lineas para facturar');
        END IF;

        -- Se bloquea el cliente antes de leer su saldo (descuento y cupo)
        SELECT id_cliente
          INTO vn_bloqueo_cliente
          FROM CLIENTE
         WHERE id_cliente = vn_id_cliente
           FOR UPDATE;

        -- 3. Descuento (valor en pesos) con la funcion existente
        param_descuento := FN_CALCULAR_DESCUENTO(vn_id_cliente, vn_subtotal);
        param_total     := vn_subtotal - param_descuento;

        -- 4. Cupo suficiente para el total ya con descuento
        vn_cupo_disponible := FN_CUPO_DISPONIBLE(vn_id_cliente);

        IF vn_cupo_disponible < param_total THEN
            RAISE_APPLICATION_ERROR(-20053, 'El cliente no tiene cupo suficiente para facturar el pedido');
        END IF;

        -- 5. Total del pedido y cambio de estado
        UPDATE PEDIDO
           SET total  = param_total,
               estado = 'CONFIRMADO'
         WHERE id_pedido = param_id_pedido;

        -- 6. Saldo pendiente del cliente
        UPDATE CLIENTE
           SET saldo_pendiente = saldo_pendiente + param_total
         WHERE id_cliente = vn_id_cliente;

        -- Sin COMMIT: la confirmacion es responsabilidad de quien invoca.

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_inicio_facturacion;

            SP_REGISTRAR_ERROR(
                'PKG_VENTAS.SP_FACTURAR_PEDIDO',
                'Pedido: ' || param_id_pedido
            );

            RAISE;
    END SP_FACTURAR_PEDIDO;

END PKG_VENTAS;
/


--==============================================================================
-- FIN DE LA PLANTILLA
--==============================================================================

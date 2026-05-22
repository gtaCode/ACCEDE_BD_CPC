create or replace PACKAGE BODY ACCEDE_PKG_WS AS

    PROCEDURE ACCEDE_SP_CONSUME_WS(
        p_master       VARCHAR2,
        p_type varchar2,
        p_id_message varchar2,
        p_user varchar2,
        p_fuente varchar2,
        vMensaje OUT VARCHAR2
    )
    IS
        l_http_req   UTL_HTTP.REQ;
        l_http_resp  UTL_HTTP.RESP;
        l_response   CLOB;
        l_url        varchar2(250);
        l_request_body CLOB;
    BEGIN

       select dato
        into l_url
        from accede_tbl_parametro
        where parametro = p_master;

        if p_master = 'WS_MA'  then
            l_request_body := '{"user": "'||p_user||'","fuente":"'||p_fuente||'"}';
        elsif p_master = 'WS_MAS'  then
            l_request_body := '{"user": "'||p_user||'","fuente":"'||p_fuente||'"}';
        elsif p_master = 'WS_ML' then
            l_request_body := '{"user": "'||p_user||'","fuente":"'||p_fuente||'"}';
        elsif p_master = 'WS_MX' then
            l_request_body := '{"user": "'||p_user||'","tipo":'||p_type||'}';
        elsif p_master = 'WS_CONF' then
            l_request_body := '{"user": "'||p_user||'","idMessage": "'||p_id_message||'","tipo":"'||p_type||'"}';
        else
            l_request_body := '{"user": "'||p_user||'"}';
        end if;

        DBMS_OUTPUT.put_line(l_request_body);

        -- Crear la solicitud HTTP
        l_http_req := UTL_HTTP.begin_request(l_url, 'POST', 'HTTP/1.1');

        UTL_HTTP.set_header(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.set_header(l_http_req, 'Content-Length',LENGTH(l_request_body));

        UTL_HTTP.write_text(l_http_req, l_request_body);

        l_http_resp := UTL_HTTP.get_response(l_http_req);
        UTL_HTTP.read_text(l_http_resp, l_response);
        UTL_HTTP.end_response(l_http_resp);

        vMensaje:= NULL;
    EXCEPTION
        WHEN OTHERS THEN
            -- Manejar errores HTTP
            DBMS_OUTPUT.put_line('Error al realizar la solicitud HTTP.');
            vMensaje:= l_response;
END;

 PROCEDURE ACCEDE_SP_SENDEMAIL_WS(
        p_master       VARCHAR2,
        p_order varchar2,
        p_doc varchar2,
        p_tipo varchar2,
        vMensaje OUT VARCHAR2
    )
    IS
        l_http_req   UTL_HTTP.REQ;
        l_http_resp  UTL_HTTP.RESP;
        l_response   CLOB;
        l_url        varchar2(250);
        l_request_body CLOB;
    BEGIN

       select dato
        into l_url
        from accede_tbl_parametro
        where parametro = p_master;

        if p_master = 'WS_EMAIL'  THEN
            l_request_body := '{"order": "'||p_order||'","documento":"'||p_doc||'","tipo":"'||p_tipo||'"}';
        end if;

        DBMS_OUTPUT.put_line(l_request_body);

        -- Crear la solicitud HTTP
        l_http_req := UTL_HTTP.begin_request(l_url, 'POST', 'HTTP/1.1');

        UTL_HTTP.set_header(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.set_header(l_http_req, 'Content-Length',LENGTH(l_request_body));

        UTL_HTTP.write_text(l_http_req, l_request_body);

        l_http_resp := UTL_HTTP.get_response(l_http_req);
        UTL_HTTP.read_text(l_http_resp, l_response);
        UTL_HTTP.end_response(l_http_resp);

        vMensaje:= NULL;
    EXCEPTION
        WHEN OTHERS THEN
            -- Manejar errores HTTP
            DBMS_OUTPUT.put_line('Error al realizar la solicitud HTTP.');
            vMensaje:= l_response;
END;

/***************************************RASTRO*********************************************************************************************/

    PROCEDURE ACCEDE_SP_DESHUESE(
        vMensaje OUT VARCHAR2,
        vToken   OUT VARCHAR2,
        p_empresa       IN VARCHAR2 DEFAULT NULL,
        p_fecha_inicial IN VARCHAR2 DEFAULT NULL,
        p_fecha_final   IN VARCHAR2 DEFAULT NULL
    )
    IS
        l_http_req       UTL_HTTP.REQ;
        l_http_resp      UTL_HTTP.RESP;

        l_response       CLOB;
        l_response_des   CLOB;
        l_buffer         VARCHAR2(32767);

        l_url            VARCHAR2(500);
        l_request_body   VARCHAR2(32767);
        l_status_code    NUMBER;

        l_token          VARCHAR2(4000);
        l_message        VARCHAR2(4000);

        l_url_deshuese          VARCHAR2(500);
        l_request_body_des      VARCHAR2(32767);
        l_status_code_des       NUMBER;

        l_cantidad_lotes        NUMBER;
        l_cantidad_detalle      NUMBER;

        l_lote                  NUMBER;
        l_anio                  NUMBER(4) := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY'));
        l_secuencia             NUMBER;
        l_id_producto           NUMBER;
        l_nombre_producto       VARCHAR2(500);
        l_piezas                NUMBER;
        l_cajas                 NUMBER;
        l_libras                NUMBER;

        l_empresa               NUMBER;
        l_fecha_inicial         VARCHAR2(30);
        l_fecha_final           VARCHAR2(30);

        l_total_insertados        NUMBER := 0;
        l_suma_rendimiento        NUMBER := 0;
        l_total_lotes_omitidos    NUMBER := 0;
        l_total_lotes_procesados  NUMBER := 0;
        l_registros_lote         NUMBER := 0;
        l_total_lotes_con_datos  NUMBER := 0;

        FUNCTION normaliza_fecha(p_fecha IN VARCHAR2) RETURN VARCHAR2 IS
            l_fecha DATE;
        BEGIN
            BEGIN
                l_fecha := TO_DATE(p_fecha, 'YYYY-MM-DD');
                RETURN TO_CHAR(l_fecha, 'YYYY-MM-DD');
            EXCEPTION WHEN OTHERS THEN NULL;
            END;

            BEGIN
                l_fecha := TO_DATE(p_fecha, 'DD/MM/YYYY');
                RETURN TO_CHAR(l_fecha, 'YYYY-MM-DD');
            EXCEPTION WHEN OTHERS THEN NULL;
            END;

            BEGIN
                l_fecha := TO_DATE(p_fecha, 'DD-MM-YYYY');
                RETURN TO_CHAR(l_fecha, 'YYYY-MM-DD');
            EXCEPTION WHEN OTHERS THEN NULL;
            END;

            RETURN p_fecha;
        END normaliza_fecha;
    BEGIN
        vMensaje := NULL;
        vToken   := NULL;

        IF p_empresa IS NULL OR p_fecha_inicial IS NULL OR p_fecha_final IS NULL THEN
            vMensaje := 'Debe ingresar empresa, fecha inicial y fecha final para consumir deshuese.';
            RETURN;
        END IF;

        BEGIN
            l_empresa := TO_NUMBER(p_empresa);
        EXCEPTION
            WHEN OTHERS THEN
                vMensaje := 'El parametro empresa debe ser numerico.';
                RETURN;
        END;

        l_fecha_inicial := normaliza_fecha(p_fecha_inicial);
        l_fecha_final   := normaliza_fecha(p_fecha_final);

        ----------------------------------------------------------------------
        -- 1. LOGIN
        ----------------------------------------------------------------------
        l_url := 'http://10.1.182.65:8080/api/gta/auth/login';

        l_request_body := '{"username":"GTA_APIusuario","password":"H7hRvYQJNRbp3R8R1cds4f","applicationName":"GCelador_APIGTA","applicationKey":"Ujr6Zaf8hjNb/SlHfw727WkvT/wW6GQduT3vUKNTgsc="}';

        DBMS_LOB.CREATETEMPORARY(l_response, TRUE);

        UTL_HTTP.SET_DETAILED_EXCP_SUPPORT(TRUE);
        UTL_HTTP.SET_TRANSFER_TIMEOUT(60);

        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');

        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'Accept', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'User-Agent', 'Oracle-UTL_HTTP');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', LENGTHB(l_request_body));

        UTL_HTTP.WRITE_TEXT(l_http_req, l_request_body);

        l_http_resp   := UTL_HTTP.GET_RESPONSE(l_http_req);
        l_status_code := l_http_resp.status_code;

        BEGIN
            LOOP
                UTL_HTTP.READ_TEXT(l_http_resp, l_buffer, 32767);
                DBMS_LOB.WRITEAPPEND(l_response, LENGTH(l_buffer), l_buffer);
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN
                NULL;
        END;

        UTL_HTTP.END_RESPONSE(l_http_resp);

        IF l_status_code NOT BETWEEN 200 AND 299 THEN
            vToken := NULL;
            vMensaje := 'ERROR HTTP LOGIN ' || l_status_code || ': ' || DBMS_LOB.SUBSTR(l_response, 1000, 1);
            RETURN;
        END IF;

        BEGIN
            APEX_JSON.PARSE(l_response);

            l_token   := APEX_JSON.GET_VARCHAR2(p_path => 'token');
            l_message := APEX_JSON.GET_VARCHAR2(p_path => 'message');
        EXCEPTION
            WHEN OTHERS THEN
                vToken := NULL;
                vMensaje := 'No se pudo parsear JSON del login: ' || SQLERRM;
                RETURN;
        END;

        IF l_token IS NULL THEN
            vToken := NULL;
            vMensaje := 'El login respondio correctamente, pero no devolvio token.';
            RETURN;
        END IF;

        vToken := l_token;

        ----------------------------------------------------------------------
        -- 2. CONSUMO DESHUESE CON BEARER TOKEN
        ----------------------------------------------------------------------
        l_url_deshuese := 'http://10.1.182.65:8080/api/gta/deshuese';

        l_request_body_des := '{"empresaID":'||TO_CHAR(l_empresa)||',"fecha_Inicial":"'||l_fecha_inicial||'","fecha_Final":"'||l_fecha_final||'"}';

        DBMS_LOB.CREATETEMPORARY(l_response_des, TRUE);

        l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url_deshuese, 'POST', 'HTTP/1.1');

        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'Accept', 'application/json');
        UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Bearer ' || l_token);
        UTL_HTTP.SET_HEADER(l_http_req, 'User-Agent', 'Oracle-UTL_HTTP');
        UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', LENGTHB(l_request_body_des));

        UTL_HTTP.WRITE_TEXT(l_http_req, l_request_body_des);

        l_http_resp       := UTL_HTTP.GET_RESPONSE(l_http_req);
        l_status_code_des := l_http_resp.status_code;

        BEGIN
            LOOP
                UTL_HTTP.READ_TEXT(l_http_resp, l_buffer, 32767);
                DBMS_LOB.WRITEAPPEND(l_response_des, LENGTH(l_buffer), l_buffer);
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN
                NULL;
        END;

        UTL_HTTP.END_RESPONSE(l_http_resp);

        IF l_status_code_des NOT BETWEEN 200 AND 299 THEN
            vMensaje := 'ERROR HTTP DESHUESE ' || l_status_code_des || ': ' || DBMS_LOB.SUBSTR(l_response_des, 1000, 1);
            DBMS_OUTPUT.PUT_LINE(vMensaje);
            RETURN;
        END IF;

        ----------------------------------------------------------------------
        -- 3. PARSEAR RESPONSE DESHUESE E INSERTAR SOLO SI SUM(RENDIMIENTO)=0
        ----------------------------------------------------------------------
        APEX_JSON.PARSE(l_response_des);

        l_cantidad_lotes := APEX_JSON.GET_COUNT(p_path => 'lotes');

        IF NVL(l_cantidad_lotes, 0) = 0 THEN
            vMensaje := 'El servicio de deshuese respondio correctamente, pero no devolvio lotes.';
            RETURN;
        END IF;

        FOR i IN 1 .. l_cantidad_lotes LOOP

            l_lote := APEX_JSON.GET_NUMBER(
                p_path => 'lotes[%d].encabezado.lote',
                p0     => i
            );

            SELECT NVL(SUM(API.RENDIMIENTO), 0)
            INTO l_suma_rendimiento
            FROM ACCEDE_TBL_API_DETALLE API
            WHERE API.LOTE = l_lote
              AND API.ANIO = l_anio;

            IF NVL(l_suma_rendimiento, 0) = 0 THEN

                DELETE FROM ACCEDE_TBL_API_DETALLE
                WHERE LOTE = l_lote
                  AND ANIO = l_anio;

                l_cantidad_detalle := APEX_JSON.GET_COUNT(
                    p_path => 'lotes[%d].detalle',
                    p0     => i
                );

                FOR j IN 1 .. l_cantidad_detalle LOOP

                    l_secuencia := APEX_JSON.GET_NUMBER(
                        p_path => 'lotes[%d].detalle[%d].secuencia',
                        p0     => i,
                        p1     => j
                    );

                    l_id_producto := APEX_JSON.GET_NUMBER(
                        p_path => 'lotes[%d].detalle[%d].idProducto',
                        p0     => i,
                        p1     => j
                    );

                    l_nombre_producto := APEX_JSON.GET_VARCHAR2(
                        p_path => 'lotes[%d].detalle[%d].nombreProducto',
                        p0     => i,
                        p1     => j
                    );

                    l_piezas := APEX_JSON.GET_NUMBER(
                        p_path => 'lotes[%d].detalle[%d].piezas',
                        p0     => i,
                        p1     => j
                    );

                    l_cajas := APEX_JSON.GET_NUMBER(
                        p_path => 'lotes[%d].detalle[%d].cajas',
                        p0     => i,
                        p1     => j
                    );

                    l_libras := APEX_JSON.GET_NUMBER(
                        p_path => 'lotes[%d].detalle[%d].libras',
                        p0     => i,
                        p1     => j
                    );

                    INSERT INTO ACCEDE_TBL_API_DETALLE (
                        LOTE,
                        ANIO,
                        SECUENCIA,
                        ID_PRODUCTO,
                        NOMBRE_PRODUCTO,
                        PIEZAS,
                        CAJAS,
                        LIBRAS,
                        ID_ESTADO
                    ) VALUES (
                        l_lote,
                        l_anio,
                        l_secuencia,
                        l_id_producto,
                        l_nombre_producto,
                        l_piezas,
                        l_cajas,
                        l_libras,
                        137
                    );

                    l_total_insertados := l_total_insertados + 1;

                END LOOP;

                l_total_lotes_procesados := l_total_lotes_procesados + 1;

            ELSE

                l_total_lotes_omitidos := l_total_lotes_omitidos + 1;

            END IF;

            SELECT COUNT(*)
            INTO l_registros_lote
            FROM ACCEDE_TBL_API_DETALLE API
            WHERE API.LOTE = l_lote
              AND API.ANIO = l_anio;

            IF NVL(l_registros_lote, 0) > 0 THEN
                l_total_lotes_con_datos := l_total_lotes_con_datos + 1;
            END IF;

        END LOOP;

        COMMIT;

        IF l_total_insertados > 0 OR l_total_lotes_con_datos > 0 THEN
            vMensaje := NULL;
        ELSE
            vMensaje := 'No inserto registros en ACCEDE_TBL_API_DETALLE y no se encontraron datos existentes para los lotes retornados por el servicio. Lotes procesados: ' || l_total_lotes_procesados ||
                        '. Lotes omitidos por rendimiento mayor a 0: ' || l_total_lotes_omitidos || '.';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                UTL_HTTP.END_RESPONSE(l_http_resp);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;

            ROLLBACK;

            vToken := NULL;
            vMensaje := 'ERROR EN ACCEDE_SP_DESHUESE: ' || SQLERRM;

            IF l_response IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('RESPONSE LOGIN ERROR: ' || DBMS_LOB.SUBSTR(l_response, 4000, 1));
            END IF;

            IF l_response_des IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('RESPONSE DESHUESE ERROR: ' || DBMS_LOB.SUBSTR(l_response_des, 4000, 1));
            END IF;
    END ACCEDE_SP_DESHUESE;

END ACCEDE_PKG_WS;
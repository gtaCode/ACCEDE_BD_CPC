

/* =========================================================
   1. TABLA ENCABEZADO
   ========================================================= */
CREATE TABLE ACCEDE_TBL_API_ENCABEZADO (
    ID              NUMBER NOT NULL,
    EMPRESA_ID      NUMBER NOT NULL,
    PERIODO         VARCHAR2(7) NOT NULL,
    LOTE            NUMBER NOT NULL,
    FECHA_INICIO    DATE NOT NULL,
    FECHA_FIN       DATE NOT NULL,
    EMPRESA         VARCHAR2(200) NOT NULL,
    TIPO            VARCHAR2(100) NOT NULL,
    FECHA_INGRESO   DATE DEFAULT SYSDATE NOT NULL
);

/* =========================================================
   2. PK ENCABEZADO
   ========================================================= */
ALTER TABLE ACCEDE_TBL_API_ENCABEZADO
ADD CONSTRAINT PK_ACCEDE_TBL_API_ENCABEZADO
PRIMARY KEY (ID);

/* =========================================================
   3. TABLA DETALLE
   ========================================================= */
CREATE TABLE ACCEDE_TBL_API_DETALLE (
    ID      NUMBER NOT NULL,
    LOTE            NUMBER NOT NULL,
    SECUENCIA       NUMBER NOT NULL,
    ID_PRODUCTO     VARCHAR2(20) NOT NULL,
    NOMBRE_PRODUCTO VARCHAR2(200) NOT NULL,
    PIEZAS          NUMBER(12,2) NOT NULL,
    CAJAS           NUMBER(12,2) NOT NULL,
    LIBRAS          NUMBER(12,2) NOT NULL,
    FECHA_INGRESO   DATE DEFAULT SYSDATE NOT NULL
);

/* =========================================================
   4. PK DETALLE
   ========================================================= */
ALTER TABLE ACCEDE_TBL_API_DETALLE
ADD CONSTRAINT PK_ACCEDE_TBL_API_DETALLE
PRIMARY KEY (ID);

/* =========================================================
   5. INDICES
   ========================================================= */

/* Índice importante por lote en encabezado */
CREATE INDEX IDX_API_ENCABEZADO_LOTE
    ON ACCEDE_TBL_API_ENCABEZADO (LOTE);

/* Opcional útil para búsquedas por periodo */
CREATE INDEX IDX_API_ENCABEZADO_PERIODO
    ON ACCEDE_TBL_API_ENCABEZADO (PERIODO);

/* Índice importante por lote en detalle */
CREATE INDEX IDX_API_DETALLE_LOTE
    ON ACCEDE_TBL_API_DETALLE (LOTE);

/* Útil para búsquedas por producto */
CREATE INDEX IDX_API_DETALLE_ID_PRODUCTO
    ON ACCEDE_TBL_API_DETALLE (ID_PRODUCTO);

/* Útil para mantener orden lógico por lote/secuencia */
CREATE INDEX IDX_API_DETALLE_LOTE_SEC
    ON ACCEDE_TBL_API_DETALLE (LOTE, SECUENCIA);



CREATE SEQUENCE ACCEDE_API_ENC
  START WITH 1
  MAXVALUE 9999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;

CREATE OR REPLACE TRIGGER ACCEDE_TRG_API_ENC
BEFORE  
INSERT ON ACCEDE_TBL_API_ENCABEZADO  
FOR EACH ROW
BEGIN
    CASE WHEN INSERTING THEN
        :NEW.ID := ACCEDE_API_ENC.NEXTVAL;
    END CASE;

END;


CREATE SEQUENCE ACCEDE_API_DET
  START WITH 1
  MAXVALUE 9999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;

CREATE OR REPLACE TRIGGER ACCEDE_TRG_API_DET
BEFORE  
INSERT ON ACCEDE_TBL_API_DETALLE  
FOR EACH ROW
BEGIN
    CASE WHEN INSERTING THEN
        :NEW.ID := ACCEDE_API_DET.NEXTVAL;
    END CASE;

END;
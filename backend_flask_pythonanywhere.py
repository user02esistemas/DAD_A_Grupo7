# -*- coding: utf-8 -*-
"""
SVE CCSPM - Sistema de Votación Electrónica
Backend REST API con Flask
Desplegado en PythonAnywhere

Estructura del archivo:
  1. IMPORTS
  2. CONFIGURACIÓN DE LA APLICACIÓN
  3. CONFIGURACIÓN DE BASE DE DATOS
  4. FUNCIONES AUXILIARES (hash, jwt, validación)
  5. DECORADORES (autenticación, auditoría)
  6. BLUEPRINTS Y ENDPOINTS
     6.01  Autenticación (/api/autenticacion)
     6.02  Usuarios (/api/usuarios)
     6.03  Roles (/api/roles)
     6.04  Elecciones (/api/elecciones)
     6.05  Caseríos (/api/caserios)
     6.06  Locales de Votación (/api/locales-votacion)
     6.07  Mesas de Sufragio (/api/mesas-sufragio)
     6.08  Comuneros (/api/comuneros)
     6.09  Partidos (/api/partidos)
     6.10  Candidatos (/api/candidatos)
     6.11  Miembros de Mesa (/api/miembros-mesa)
     6.12  Votación (/api/votacion)
     6.13  Resultados (/api/resultados)
     6.14  Dashboard (/api/dashboard)
     6.15  Auditoría (/api/auditoria)
  7. PROGRAMADOR DE ESTADOS DE ELECCIÓN
  8. INICIO DE LA APLICACIÓN
"""

# =============================================================================
# 1. IMPORTS
# =============================================================================
import base64
import hashlib
import hmac
import json
import os
import random
import string
import time
from zoneinfo import ZoneInfo
from datetime import datetime, timedelta
from functools import wraps
from urllib.parse import urlencode

import jwt
import pymysql
from flask import Flask, Blueprint, jsonify, request, g
from flask_cors import CORS

# =============================================================================
# 2. CONFIGURACIÓN DE LA APLICACIÓN
# =============================================================================
app = Flask(__name__)
CORS(app, supports_credentials=True)

# Clave secreta para firmar tokens JWT
CLAVE_SECRETA = os.environ.get('CLAVE_SECRETA', 'ccspm_sve_clave_secreta_jwt_2024')
TOKEN_EXPIRACION_HORAS = 8

# Configuración de PythonAnywhere
DB_CONFIG = {
    'host': 'inosies.mysql.pythonanywhere-services.com',
    'user': 'inosies',
    'password': '0207Siesquen',
    'database': 'inosies$sve_ccspm',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

# Estados de elección (deben coincidir con el ENUM de la BD)
ESTADO_PROXIMA = 'PROXIMA'
ESTADO_INSCRIPCIONES_ABIERTAS = 'INSCRIPCIONES_ABIERTAS'
ESTADO_CERRADA = 'CERRADA'
ESTADO_EN_VOTACION = 'EN_VOTACION'
ESTADO_FINALIZADA = 'FINALIZADA'

# Intentos máximos de inicio de sesión
MAX_INTENTOS_FALLIDOS = 3

# =============================================================================
# 3. CONFIGURACIÓN DE BASE DE DATOS
# =============================================================================

def obtener_conexion():
    """Obtiene una conexión a la base de datos MySQL."""
    try:
        conexion = pymysql.connect(**DB_CONFIG)
        return conexion
    except pymysql.Error as error:
        print(f"Error de conexión a la BD: {error}")
        return None


def ejecutar_consulta(sql, params=None, obtener_id=False, una_fila=False):
    """
    Ejecuta una consulta SQL y retorna los resultados.
    obtener_id=True: retorna el último ID insertado (para INSERT)
    una_fila=True: retorna una sola fila como diccionario
    """
    conexion = obtener_conexion()
    if not conexion:
        return None
    try:
        with conexion.cursor() as cursor:
            cursor.execute(sql, params)
            if obtener_id:
                conexion.commit()
                return cursor.lastrowid
            if sql.strip().upper().startswith(('INSERT', 'UPDATE', 'DELETE')):
                conexion.commit()
                return cursor.rowcount
            if una_fila:
                return cursor.fetchone()
            return cursor.fetchall()
    except pymysql.Error as error:
        print(f"Error SQL: {error}")
        if 'conexion' in locals():
            conexion.rollback()
        return None
    finally:
        conexion.close()


# =============================================================================
# 4. FUNCIONES AUXILIARES
# =============================================================================

# --- Hashing de contraseñas ---

def generar_salt(longitud=16):
    """Genera una cadena aleatoria para usar como salt."""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=longitud))


def encriptar_contrasena(contrasena, salt=None):
    """Encripta una contraseña con SHA-256 + salt."""
    if salt is None:
        salt = generar_salt()
    hash_obj = hashlib.sha256((contrasena + salt).encode('utf-8'))
    return f"{salt}${hash_obj.hexdigest()}"


def verificar_contrasena(contrasena, hash_almacenado):
    """Verifica si una contraseña coincide con el hash almacenado.
    Soporta dos formatos:
      - Nuevo (Python): salt$hexdigest
      - Heredado (Java): salt_base64:hash_base64
    """
    if not hash_almacenado:
        return False

    # Formato nuevo: salt$hexdigest
    if '$' in hash_almacenado:
        try:
            salt = hash_almacenado.split('$', 1)[0]
            hash_calculado = encriptar_contrasena(contrasena, salt)
            return hmac.compare_digest(hash_calculado, hash_almacenado)
        except (ValueError, IndexError):
            pass

    # Formato heredado Java: PBKDF2WithHmacSHA256, 65536 iteraciones, salt y hash en base64
    if ':' in hash_almacenado:
        try:
            partes = hash_almacenado.split(':', 1)
            salt_bytes = base64.b64decode(partes[0])
            hash_esperado = base64.b64decode(partes[1])
            hash_actual = hashlib.pbkdf2_hmac('sha256', contrasena.encode('utf-8'), salt_bytes, 65536, dklen=32)
            return hmac.compare_digest(hash_actual, hash_esperado)
        except Exception:
            pass

    # Compatibilidad: SHA-256 puro (sin salt)
    try:
        return hmac.compare_digest(
            hashlib.sha256(contrasena.encode('utf-8')).hexdigest(),
            hash_almacenado
        )
    except Exception:
        return False


# --- Tokens JWT ---

def generar_token(payload):
    """Genera un token JWT."""
    payload['exp'] = datetime.utcnow() + timedelta(hours=TOKEN_EXPIRACION_HORAS)
    payload['iat'] = datetime.utcnow()
    return jwt.encode(payload, CLAVE_SECRETA, algorithm='HS256')


def decodificar_token(token):
    """Decodifica y valida un token JWT."""
    try:
        return jwt.decode(token, CLAVE_SECRETA, algorithms=['HS256'])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


# --- Generación de códigos ---

def generar_codigo_personal(longitud=8):
    """Genera un código personal alfanumérico para un comunero."""
    caracteres = string.ascii_uppercase + string.digits
    return ''.join(random.choices(caracteres, k=longitud))


def generar_clave_votacion(longitud=6):
    """Genera una clave de votación numérica de 6 dígitos."""
    return ''.join(random.choices(string.digits, k=longitud))


def generar_hash_integridad(id_eleccion, id_comunero, id_candidato, es_voto_blanco, ip_origen):
    """Genera un hash de integridad para un voto."""
    datos = f"{id_eleccion}|{id_comunero}|{id_candidato}|{es_voto_blanco}|{ip_origen}|{time.time()}"
    return hashlib.sha256(datos.encode('utf-8')).hexdigest()


# --- Obtención de IP ---

def obtener_ip():
    """Obtiene la IP del cliente."""
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    return request.remote_addr or '127.0.0.1'


# --- Respuesta estándar ---

def respuesta(exito=True, mensaje='', datos=None, codigo=200):
    """Formatea una respuesta JSON estándar."""
    cuerpo = {'exito': exito, 'mensaje': mensaje}
    if datos is not None:
        cuerpo['datos'] = datos
    return jsonify(cuerpo), codigo


def respuesta_paginada(lista_datos, total, pagina, por_pagina):
    """Formatea una respuesta JSON paginada."""
    return jsonify({
        'exito': True,
        'datos': lista_datos,
        'total': total,
        'pagina': pagina,
        'por_pagina': por_pagina,
        'total_paginas': (total + por_pagina - 1) // por_pagina if por_pagina > 0 else 0
    })


# --- Registro de auditoría ---

def registrar_auditoria(id_usuario, modulo, accion, detalle=''):
    """Registra un evento en la tabla de auditoría."""
    sql = """INSERT INTO auditoria (id_usuario, modulo, accion, detalle, ip_origen, fecha_evento)
             VALUES (%s, %s, %s, %s, %s, NOW())"""
    ejecutar_consulta(sql, (id_usuario, modulo, accion, detalle, obtener_ip()))


def registrar_historial_login(id_usuario, nombre_usuario, exito, motivo=''):
    """Registra un intento de inicio de sesión."""
    sql = """INSERT INTO historial_login (id_usuario, nombre_usuario_intento, exito, motivo, ip_origen)
             VALUES (%s, %s, %s, %s, %s)"""
    ejecutar_consulta(sql, (id_usuario, nombre_usuario, exito, motivo, obtener_ip()))


# --- Paginación ---

def obtener_paginacion():
    """Extrae parámetros de paginación de la solicitud."""
    pagina = request.args.get('pagina', 1, type=int)
    por_pagina = request.args.get('por_pagina', 10, type=int)
    if pagina < 1:
        pagina = 1
    if por_pagina < 1:
        por_pagina = 10
    if por_pagina > 100:
        por_pagina = 100
    offset = (pagina - 1) * por_pagina
    return pagina, por_pagina, offset


# =============================================================================
# 5. DECORADORES
# =============================================================================

def token_requerido(f):
    """Decorador que verifica que la solicitud tenga un token JWT válido."""
    @wraps(f)
    def decorador(*args, **kwargs):
        token = None
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]

        if not token:
            return respuesta(False, 'Token de autenticación requerido', codigo=401)

        payload = decodificar_token(token)
        if not payload:
            return respuesta(False, 'Token inválido o expirado', codigo=401)

        g.usuario_actual = payload
        return f(*args, **kwargs)
    return decorador


def auditar(modulo):
    """Decorador que registra automáticamente la acción en auditoría."""
    def decorador_externo(f):
        @wraps(f)
        def decorador(*args, **kwargs):
            resultado = f(*args, **kwargs)
            id_usuario = g.get('usuario_actual', {}).get('id_usuario')
            accion = f.__name__.replace('_', ' ').upper()
            registrar_auditoria(id_usuario, modulo, accion, f"Endpoint: {request.path}")
            return resultado
        return decorador
    return decorador_externo


# =============================================================================
# 6. BLUEPRINTS Y ENDPOINTS
# =============================================================================

# ---------------------------------------------------------------------------
# 6.01 AUTENTICACIÓN  /api/autenticacion
# ---------------------------------------------------------------------------
autenticacion_bp = Blueprint('autenticacion', __name__, url_prefix='/api/autenticacion')


@autenticacion_bp.route('/iniciar-sesion', methods=['POST'])
def iniciar_sesion():
    """Inicia sesión con nombre de usuario y contraseña."""
    datos = request.get_json(silent=True) or {}
    nombre_usuario = datos.get('nombreUsuario', '').strip()
    contrasena = datos.get('contrasena', '')

    if not nombre_usuario or not contrasena:
        return respuesta(False, 'Nombre de usuario y contraseña requeridos', codigo=400)

    sql = """SELECT u.id_usuario, u.nombres, u.apellidos, u.nombre_usuario,
                    u.contrasena_hash, u.id_rol, r.nombre_rol, u.estado, u.intentos_fallidos
             FROM usuarios u
             INNER JOIN roles r ON u.id_rol = r.id_rol
             WHERE u.nombre_usuario = %s"""
    usuario = ejecutar_consulta(sql, (nombre_usuario,), una_fila=True)

    if not usuario:
        registrar_historial_login(None, nombre_usuario, False, 'Usuario no encontrado')
        return respuesta(False, 'Credenciales incorrectas', codigo=401)

    id_usuario = usuario['id_usuario']

    # Verificar si la cuenta está bloqueada
    if usuario['estado'] == 'BLOQUEADO' or usuario['estado'] == 'bloqueado':
        registrar_historial_login(id_usuario, nombre_usuario, False, 'Cuenta bloqueada')
        return respuesta(False, 'Cuenta bloqueada. Contacte al administrador.', codigo=403)

    # Verificar contraseña
    if not verificar_contrasena(contrasena, usuario['contrasena_hash']):
        intentos = (usuario['intentos_fallidos'] or 0) + 1
        nuevo_estado = 'BLOQUEADO' if intentos >= MAX_INTENTOS_FALLIDOS else usuario['estado']
        sql_update = "UPDATE usuarios SET intentos_fallidos = %s, estado = %s WHERE id_usuario = %s"
        ejecutar_consulta(sql_update, (intentos, nuevo_estado, id_usuario))
        registrar_historial_login(id_usuario, nombre_usuario, False,
                                  f'Contraseña incorrecta. Intento {intentos}/{MAX_INTENTOS_FALLIDOS}')
        mensaje = 'Credenciales incorrectas'
        if intentos >= MAX_INTENTOS_FALLIDOS:
            mensaje = 'Cuenta bloqueada por exceder intentos fallidos.'
        return respuesta(False, mensaje, codigo=401)

    # Resetear intentos y actualizar último acceso
    ahora = datetime.now(ZoneInfo('America/Lima')).strftime('%Y-%m-%d %H:%M:%S')
    sql_reset = "UPDATE usuarios SET intentos_fallidos = 0, ultimo_acceso = %s WHERE id_usuario = %s"
    ejecutar_consulta(sql_reset, (ahora, id_usuario))
    registrar_historial_login(id_usuario, nombre_usuario, True, 'Inicio de sesión exitoso')

    # Obtener permisos (módulos)
    modulos = ejecutar_consulta(
        "SELECT modulo FROM usuarios_modulos WHERE id_usuario = %s", (id_usuario,))
    lista_modulos = [m['modulo'] for m in modulos] if modulos else []

    # Generar token
    payload_token = {
        'id_usuario': id_usuario,
        'nombre_usuario': usuario['nombre_usuario'],
        'nombres': usuario['nombres'],
        'apellidos': usuario['apellidos'],
        'id_rol': usuario['id_rol'],
        'nombre_rol': usuario['nombre_rol'],
        'modulos': lista_modulos
    }
    token = generar_token(payload_token)

    datos_respuesta = {
        'token': token,
        'usuario': {
            'idUsuario': id_usuario,
            'nombres': usuario['nombres'],
            'apellidos': usuario['apellidos'],
            'nombreUsuario': usuario['nombre_usuario'],
            'idRol': usuario['id_rol'],
            'nombreRol': usuario['nombre_rol'],
            'modulos': lista_modulos
        }
    }
    return respuesta(True, 'Inicio de sesión exitoso', datos_respuesta)


@autenticacion_bp.route('/cerrar-sesion', methods=['POST'])
@token_requerido
def cerrar_sesion():
    """Cierra la sesión del usuario actual."""
    id_usuario = g.usuario_actual.get('id_usuario')
    registrar_auditoria(id_usuario, 'AUTENTICACION', 'CIERRE SESION', 'Cierre de sesión exitoso')
    return respuesta(True, 'Sesión cerrada exitosamente')


@autenticacion_bp.route('/verificar', methods=['GET'])
@token_requerido
def verificar_token():
    """Verifica que el token actual sea válido."""
    return respuesta(True, 'Token válido', g.usuario_actual)

# ---------------------------------------------------------------------------
# 6.02 USUARIOS  /api/usuarios
# ---------------------------------------------------------------------------
usuarios_bp = Blueprint('usuarios', __name__, url_prefix='/api/usuarios')


@usuarios_bp.route('', methods=['GET'])
@token_requerido
def listar_usuarios():
    """Lista usuarios con paginación y búsqueda."""
    pagina, por_pagina, offset = obtener_paginacion()
    busqueda = request.args.get('busqueda', '').strip()

    sql_base = """FROM usuarios u INNER JOIN roles r ON u.id_rol = r.id_rol"""
    params = []

    if busqueda:
        sql_base += " WHERE u.dni LIKE %s OR u.nombres LIKE %s OR u.apellidos LIKE %s OR u.nombre_usuario LIKE %s"
        like = f"%{busqueda}%"
        params = [like, like, like, like]

    # Total
    total_row = ejecutar_consulta(f"SELECT COUNT(*) cantidad {sql_base}", params, una_fila=True)
    total = total_row['cantidad'] if total_row else 0

    # Datos
    sql_datos = f"""SELECT u.id_usuario, u.nombres, u.apellidos, u.dni, u.telefono, u.correo,
                           u.nombre_usuario, u.id_rol, r.nombre_rol, u.estado, u.intentos_fallidos,
                           u.ultimo_acceso
                    {sql_base}
                    ORDER BY u.id_usuario ASC LIMIT %s OFFSET %s"""
    lista = ejecutar_consulta(sql_datos, params + [por_pagina, offset])

    datos_formateados = []
    if lista:
        for u in lista:
            datos_formateados.append({
                'idUsuario': u['id_usuario'],
                'nombres': u['nombres'],
                'apellidos': u['apellidos'],
                'dni': u['dni'],
                'telefono': u.get('telefono', ''),
                'correo': u.get('correo', ''),
                'nombreUsuario': u['nombre_usuario'],
                'idRol': u['id_rol'],
                'nombreRol': u['nombre_rol'],
                'estado': u['estado'],
                'intentosFallidos': u.get('intentos_fallidos', 0),
                'ultimoAcceso': str(u['ultimo_acceso']) if u.get('ultimo_acceso') else None
            })
    return respuesta_paginada(datos_formateados, total, pagina, por_pagina)


@usuarios_bp.route('/<int:id_usuario>', methods=['GET'])
@token_requerido
def obtener_usuario(id_usuario):
    """Obtiene un usuario por su ID."""
    sql = """SELECT u.id_usuario, u.nombres, u.apellidos, u.dni, u.telefono, u.correo,
                    u.nombre_usuario, u.id_rol, r.nombre_rol, u.estado, u.intentos_fallidos
             FROM usuarios u
             INNER JOIN roles r ON u.id_rol = r.id_rol
             WHERE u.id_usuario = %s"""
    usuario = ejecutar_consulta(sql, (id_usuario,), una_fila=True)
    if not usuario:
        return respuesta(False, 'Usuario no encontrado', codigo=404)

    # Obtener módulos del usuario
    modulos = ejecutar_consulta(
        "SELECT modulo FROM usuarios_modulos WHERE id_usuario = %s", (id_usuario,))
    lista_modulos = [m['modulo'] for m in modulos] if modulos else []

    datos = {
        'idUsuario': usuario['id_usuario'],
        'nombres': usuario['nombres'],
        'apellidos': usuario['apellidos'],
        'dni': usuario['dni'],
        'telefono': usuario.get('telefono', ''),
        'correo': usuario.get('correo', ''),
        'nombreUsuario': usuario['nombre_usuario'],
        'idRol': usuario['id_rol'],
        'nombreRol': usuario['nombre_rol'],
        'estado': usuario['estado'],
        'intentosFallidos': usuario.get('intentos_fallidos', 0),
        'modulos': lista_modulos
    }
    return respuesta(True, '', datos)


@usuarios_bp.route('', methods=['POST'])
@token_requerido
def crear_usuario():
    """Crea un nuevo usuario."""
    datos = request.get_json(silent=True) or {}
    campos_requeridos = ['nombres', 'apellidos', 'dni', 'nombreUsuario', 'contrasena', 'idRol']
    for campo in campos_requeridos:
        if not datos.get(campo):
            return respuesta(False, f"El campo '{campo}' es requerido", codigo=400)

    # Verificar duplicados
    existente = ejecutar_consulta(
        """SELECT COUNT(*) cantidad FROM usuarios
           WHERE nombre_usuario = %s OR dni = %s OR correo = %s""",
        (datos['nombreUsuario'], datos['dni'], datos.get('correo', '')),
        una_fila=True
    )
    if existente and existente['cantidad'] > 0:
        return respuesta(False, 'Ya existe un usuario con el mismo DNI, correo o nombre de usuario', codigo=409)

    hash_contrasena = encriptar_contrasena(datos['contrasena'])

    ahora = datetime.now(ZoneInfo('America/Lima')).strftime('%Y-%m-%d %H:%M:%S')
    sql = """INSERT INTO usuarios (nombres, apellidos, dni, telefono, correo, nombre_usuario,
                                   contrasena_hash, id_rol, estado, fecha_creacion, fecha_actualizacion)
             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        datos['nombres'], datos['apellidos'], datos['dni'],
        datos.get('telefono', ''), datos.get('correo', ''),
        datos['nombreUsuario'], hash_contrasena, datos['idRol'],
        datos.get('estado', 'ACTIVO'), ahora, ahora
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear el usuario', codigo=500)

    # Asignar módulos
    modulos = datos.get('modulos', [])
    if modulos:
        for modulo in modulos:
            ejecutar_consulta(
                "INSERT INTO usuarios_modulos (id_usuario, modulo) VALUES (%s, %s)",
                (nuevo_id, modulo))

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'USUARIOS', 'CREAR',
                        f"Usuario creado: {datos['nombreUsuario']}")
    return respuesta(True, 'Usuario creado exitosamente', {'idUsuario': nuevo_id})


@usuarios_bp.route('/<int:id_usuario>', methods=['PUT'])
@token_requerido
def actualizar_usuario(id_usuario):
    """Actualiza un usuario existente."""
    existente = ejecutar_consulta(
        "SELECT id_usuario FROM usuarios WHERE id_usuario = %s", (id_usuario,), una_fila=True)
    if not existente:
        return respuesta(False, 'Usuario no encontrado', codigo=404)

    datos = request.get_json(silent=True) or {}

    # Verificar duplicados excluyendo el actual
    existente_dup = ejecutar_consulta(
        """SELECT COUNT(*) cantidad FROM usuarios
           WHERE (nombre_usuario = %s OR dni = %s OR correo = %s) AND id_usuario != %s""",
        (datos.get('nombreUsuario', ''), datos.get('dni', ''), datos.get('correo', ''), id_usuario),
        una_fila=True
    )
    if existente_dup and existente_dup['cantidad'] > 0:
        return respuesta(False, 'Ya existe otro usuario con el mismo DNI, correo o nombre de usuario', codigo=409)

    ahora = datetime.now(ZoneInfo('America/Lima')).strftime('%Y-%m-%d %H:%M:%S')
    sql = """UPDATE usuarios SET nombres = %s, apellidos = %s, dni = %s, telefono = %s,
              correo = %s, id_rol = %s, estado = %s, fecha_actualizacion = %s WHERE id_usuario = %s"""
    ejecutar_consulta(sql, (
        datos.get('nombres', ''), datos.get('apellidos', ''),
        datos.get('dni', ''), datos.get('telefono', ''),
        datos.get('correo', ''), datos.get('idRol', 1),
        datos.get('estado', 'ACTIVO'), ahora, id_usuario
    ))

    # Actualizar contraseña si se proporcionó
    if datos.get('contrasena'):
        hash_nueva = encriptar_contrasena(datos['contrasena'])
        ahora = datetime.now(ZoneInfo('America/Lima')).strftime('%Y-%m-%d %H:%M:%S')
        ejecutar_consulta(
            "UPDATE usuarios SET contrasena_hash = %s, fecha_actualizacion = %s WHERE id_usuario = %s",
            (hash_nueva, ahora, id_usuario))

    # Actualizar módulos
    modulos = datos.get('modulos')
    if modulos is not None:
        ejecutar_consulta("DELETE FROM usuarios_modulos WHERE id_usuario = %s", (id_usuario,))
        for modulo in modulos:
            ejecutar_consulta(
                "INSERT INTO usuarios_modulos (id_usuario, modulo) VALUES (%s, %s)",
                (id_usuario, modulo))

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'USUARIOS', 'ACTUALIZAR',
                        f"Usuario ID {id_usuario} actualizado")
    return respuesta(True, 'Usuario actualizado exitosamente')


@usuarios_bp.route('/<int:id_usuario>/cambiar-contrasena', methods=['POST'])
@token_requerido
def cambiar_contrasena(id_usuario):
    """Cambia la contraseña de un usuario."""
    datos = request.get_json(silent=True) or {}
    nueva_contrasena = datos.get('nuevaContrasena', '')
    if not nueva_contrasena:
        return respuesta(False, 'Nueva contraseña requerida', codigo=400)

    hash_nueva = encriptar_contrasena(nueva_contrasena)
    ejecutar_consulta(
        "UPDATE usuarios SET contrasena_hash = %s, estado = 'ACTIVO', intentos_fallidos = 0 WHERE id_usuario = %s",
        (hash_nueva, id_usuario))

    return respuesta(True, 'Contraseña cambiada exitosamente')



@usuarios_bp.route('/<int:id_usuario>', methods=['DELETE'])
@token_requerido
def eliminar_usuario(id_usuario):
    """Elimina un usuario de la base de datos."""
    existente = ejecutar_consulta(
        "SELECT id_usuario FROM usuarios WHERE id_usuario = %s", (id_usuario,), una_fila=True)
    if not existente:
        return respuesta(False, 'Usuario no encontrado', codigo=404)

    ejecutar_consulta("DELETE FROM usuarios_modulos WHERE id_usuario = %s", (id_usuario,))
    ejecutar_consulta("DELETE FROM usuarios WHERE id_usuario = %s", (id_usuario,))

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'USUARIOS', 'ELIMINAR',
                        f"Usuario ID {id_usuario} eliminado permanentemente")
    return respuesta(True, 'Usuario eliminado permanentemente')







# ---------------------------------------------------------------------------
# 6.03 ROLES  /api/roles
# ---------------------------------------------------------------------------
roles_bp = Blueprint('roles', __name__, url_prefix='/api/roles')


@roles_bp.route('', methods=['GET'])
@token_requerido
def listar_roles():
    """Lista todos los roles activos."""
    roles = ejecutar_consulta(
        "SELECT id_rol, nombre_rol, descripcion FROM roles WHERE activo = 1 ORDER BY nombre_rol")
    lista = []
    if roles:
        for r in roles:
            lista.append({
                'idRol': r['id_rol'],
                'nombreRol': r['nombre_rol'],
                'descripcion': r.get('descripcion', '')
            })
    return respuesta(True, '', lista)


@roles_bp.route('/modulos', methods=['GET'])
@token_requerido
def listar_modulos():
    """Lista todos los módulos del sistema."""
    modulos = [
        {'codigo': 'DASHBOARD', 'nombre': 'Dashboard'},
        {'codigo': 'USUARIOS', 'nombre': 'Gestión de Usuarios'},
        {'codigo': 'COMUNEROS', 'nombre': 'Gestión de Comuneros'},
        {'codigo': 'ELECCIONES', 'nombre': 'Gestión de Elecciones'},
        {'codigo': 'PARTIDOS_CANDIDATOS', 'nombre': 'Partidos y Candidatos'},
        {'codigo': 'CASERIOS', 'nombre': 'Gestión de Caseríos'},
        {'codigo': 'LOCALES_VOTACION', 'nombre': 'Locales de Votación'},
        {'codigo': 'MESAS_SUFRAGIO', 'nombre': 'Mesas de Sufragio'},
        {'codigo': 'MIEMBROS_MESA', 'nombre': 'Miembros de Mesa'},
        {'codigo': 'RESULTADOS', 'nombre': 'Resultados'},
        {'codigo': 'AUDITORIA', 'nombre': 'Auditoría'}
    ]
    return respuesta(True, '', modulos)


# ---------------------------------------------------------------------------
# 6.04 ELECCIONES  /api/elecciones
# ---------------------------------------------------------------------------
elecciones_bp = Blueprint('elecciones', __name__, url_prefix='/api/elecciones')


@elecciones_bp.route('', methods=['GET'])
@token_requerido
def listar_elecciones():
    """Lista elecciones con paginación y búsqueda."""
    pagina, por_pagina, offset = obtener_paginacion()
    busqueda = request.args.get('busqueda', '').strip()

    sql_base = "FROM elecciones"
    params = []

    if busqueda:
        sql_base += " WHERE nombre_eleccion LIKE %s OR estado LIKE %s"
        like = f"%{busqueda}%"
        params = [like, like]

    total_row = ejecutar_consulta(f"SELECT COUNT(*) cantidad {sql_base}", params, una_fila=True)
    total = total_row['cantidad'] if total_row else 0

    sql_datos = f"""SELECT id_eleccion, nombre_eleccion, fecha_inicio_inscripcion, fecha_cierre_inscripcion,
                           hora_inicio_inscripcion, hora_fin_inscripcion, fecha_votacion,
                           hora_inicio_votacion, hora_fin_votacion, estado, activa, descripcion
                    {sql_base}
                    ORDER BY id_eleccion DESC LIMIT %s OFFSET %s"""
    lista = ejecutar_consulta(sql_datos, params + [por_pagina, offset])

    datos = []
    if lista:
        for e in lista:
            estado_calculado = _calcular_estado_auto(
                str(e.get('fecha_inicio_inscripcion', '')) or None,
                e.get('hora_inicio_inscripcion'),
                str(e.get('fecha_cierre_inscripcion', '')) or None,
                e.get('hora_fin_inscripcion'),
                str(e.get('fecha_votacion', '')) or None,
                e.get('hora_inicio_votacion'),
                e.get('hora_fin_votacion'))
            datos.append({
                'idEleccion': e['id_eleccion'],
                'nombreEleccion': e['nombre_eleccion'],
                'fechaInicioInscripcion': str(e.get('fecha_inicio_inscripcion', '')) if e.get('fecha_inicio_inscripcion') else '',
                'fechaCierreInscripcion': str(e.get('fecha_cierre_inscripcion', '')) if e.get('fecha_cierre_inscripcion') else '',
                'horaInicioInscripcion': _fmt_hora(e.get('hora_inicio_inscripcion')),
                'horaFinInscripcion': _fmt_hora(e.get('hora_fin_inscripcion')),
                'fechaVotacion': str(e.get('fecha_votacion', '')) if e.get('fecha_votacion') else '',
                'horaInicioVotacion': _fmt_hora(e.get('hora_inicio_votacion')),
                'horaFinVotacion': _fmt_hora(e.get('hora_fin_votacion')),
                'estado': estado_calculado,
                'activa': bool(e.get('activa', 0)),
                'descripcion': e.get('descripcion', '')
            })
    return respuesta_paginada(datos, total, pagina, por_pagina)


@elecciones_bp.route('/activa', methods=['GET'])
def eleccion_activa():
    """Obtiene la elección activa actual."""
    sql = """SELECT id_eleccion, nombre_eleccion, fecha_inicio_inscripcion, fecha_cierre_inscripcion,
                    hora_inicio_inscripcion, hora_fin_inscripcion, fecha_votacion,
                    hora_inicio_votacion, hora_fin_votacion, estado, activa, descripcion
             FROM elecciones WHERE activa = 1 LIMIT 1"""
    eleccion = ejecutar_consulta(sql, una_fila=True)
    if not eleccion:
        return respuesta(False, 'No hay elección activa', codigo=404)

    estado_calculado = _calcular_estado_auto(
        str(eleccion.get('fecha_inicio_inscripcion', '')) or None,
        eleccion.get('hora_inicio_inscripcion'),
        str(eleccion.get('fecha_cierre_inscripcion', '')) or None,
        eleccion.get('hora_fin_inscripcion'),
        str(eleccion.get('fecha_votacion', '')) or None,
        eleccion.get('hora_inicio_votacion'),
        eleccion.get('hora_fin_votacion'))
    datos = {
        'idEleccion': eleccion['id_eleccion'],
        'nombreEleccion': eleccion['nombre_eleccion'],
        'fechaInicioInscripcion': str(eleccion.get('fecha_inicio_inscripcion', '')) if eleccion.get('fecha_inicio_inscripcion') else '',
        'fechaCierreInscripcion': str(eleccion.get('fecha_cierre_inscripcion', '')) if eleccion.get('fecha_cierre_inscripcion') else '',
        'horaInicioInscripcion': _fmt_hora(eleccion.get('hora_inicio_inscripcion')),
        'horaFinInscripcion': _fmt_hora(eleccion.get('hora_fin_inscripcion')),
        'fechaVotacion': str(eleccion.get('fecha_votacion', '')) if eleccion.get('fecha_votacion') else '',
        'horaInicioVotacion': _fmt_hora(eleccion.get('hora_inicio_votacion')),
        'horaFinVotacion': _fmt_hora(eleccion.get('hora_fin_votacion')),
        'estado': estado_calculado,
        'activa': bool(eleccion.get('activa', 0)),
        'descripcion': eleccion.get('descripcion', '')
    }
    return respuesta(True, '', datos)


@elecciones_bp.route('/<int:id_eleccion>', methods=['GET'])
@token_requerido
def obtener_eleccion(id_eleccion):
    """Obtiene una elección por su ID."""
    sql = """SELECT id_eleccion, nombre_eleccion, fecha_inicio_inscripcion, fecha_cierre_inscripcion,
                    hora_inicio_inscripcion, hora_fin_inscripcion, fecha_votacion,
                    hora_inicio_votacion, hora_fin_votacion, estado, activa, descripcion
             FROM elecciones WHERE id_eleccion = %s"""
    eleccion = ejecutar_consulta(sql, (id_eleccion,), una_fila=True)
    if not eleccion:
        return respuesta(False, 'Elección no encontrada', codigo=404)

    estado_calculado = _calcular_estado_auto(
        str(eleccion.get('fecha_inicio_inscripcion', '')) or None,
        eleccion.get('hora_inicio_inscripcion'),
        str(eleccion.get('fecha_cierre_inscripcion', '')) or None,
        eleccion.get('hora_fin_inscripcion'),
        str(eleccion.get('fecha_votacion', '')) or None,
        eleccion.get('hora_inicio_votacion'),
        eleccion.get('hora_fin_votacion'))
    datos = {
        'idEleccion': eleccion['id_eleccion'],
        'nombreEleccion': eleccion['nombre_eleccion'],
        'fechaInicioInscripcion': str(eleccion.get('fecha_inicio_inscripcion', '')) if eleccion.get('fecha_inicio_inscripcion') else '',
        'fechaCierreInscripcion': str(eleccion.get('fecha_cierre_inscripcion', '')) if eleccion.get('fecha_cierre_inscripcion') else '',
        'horaInicioInscripcion': _fmt_hora(eleccion.get('hora_inicio_inscripcion')),
        'horaFinInscripcion': _fmt_hora(eleccion.get('hora_fin_inscripcion')),
        'fechaVotacion': str(eleccion.get('fecha_votacion', '')) if eleccion.get('fecha_votacion') else '',
        'horaInicioVotacion': _fmt_hora(eleccion.get('hora_inicio_votacion')),
        'horaFinVotacion': _fmt_hora(eleccion.get('hora_fin_votacion')),
        'estado': estado_calculado,
        'activa': bool(eleccion.get('activa', 0)),
        'descripcion': eleccion.get('descripcion', '')
    }
    return respuesta(True, '', datos)


def _fmt_hora(val):
    """Convierte timedelta, int, o string a HH:MM:SS con leading zeros."""
    if val is None:
        return ''
    if isinstance(val, (int, float)):
        total = int(val)
        h = total // 3600
        m = (total % 3600) // 60
        s = total % 60
        return f"{h:02d}:{m:02d}:{s:02d}"
    if isinstance(val, timedelta):
        total = int(val.total_seconds())
        h = total // 3600
        m = (total % 3600) // 60
        s = total % 60
        return f"{h:02d}:{m:02d}:{s:02d}"
    s = str(val)
    if s.count(':') == 2:
        partes = s.split(':')
        return f"{int(partes[0]):02d}:{partes[1]}:{partes[2]}"
    return s


def _calcular_estado_auto(fecha_ini_ins, hora_ini_ins, fecha_fin_ins, hora_fin_ins, fecha_vot, hora_ini_vot, hora_fin_vot):
    """Calcula el estado según las fechas/horas actuales (misma lógica que SrvGestionElecciones.java).
    Usa string comparison YYYY-MM-DD HH:MM con zona horaria de Perú (America/Lima)."""
    try:
        from zoneinfo import ZoneInfo
        tz = ZoneInfo('America/Lima')
    except ImportError:
        from pytz import timezone
        tz = timezone('America/Lima')
    ahora_str = datetime.now(tz).strftime('%Y-%m-%d %H:%M')
    def _hora_str(hora):
        """Devuelve HH:MM (o 00:00 si es None/vacío)."""
        h = _fmt_hora(hora)
        return (h[:5] if len(h) >= 5 else "00:00")
    ini_ins = f"{fecha_ini_ins} {_hora_str(hora_ini_ins)}" if fecha_ini_ins else None
    fin_ins = f"{fecha_fin_ins} {_hora_str(hora_fin_ins)}" if fecha_fin_ins else None
    ini_vot = f"{fecha_vot} {_hora_str(hora_ini_vot)}" if fecha_vot else None
    fin_vot = f"{fecha_vot} {_hora_str(hora_fin_vot)}" if fecha_vot else None
    if fin_vot and ahora_str > fin_vot:
        return ESTADO_FINALIZADA
    if ini_vot and fin_vot and ahora_str >= ini_vot and ahora_str <= fin_vot:
        return ESTADO_EN_VOTACION
    if fin_ins and ini_vot and ahora_str > fin_ins and ahora_str < ini_vot:
        return ESTADO_PROXIMA
    if ini_ins and fin_ins and ahora_str >= ini_ins and ahora_str <= fin_ins:
        return ESTADO_INSCRIPCIONES_ABIERTAS
    return ESTADO_PROXIMA


def _validar_inscripciones_abiertas(mensaje_accion="realizar esta operaci\u00f3n"):
    """Verifica que exista una elección activa en estado INSCRIPCIONES_ABIERTAS."""
    eleccion = ejecutar_consulta(
        "SELECT id_eleccion, estado FROM elecciones WHERE activa = 1 LIMIT 1",
        una_fila=True)
    if not eleccion:
        return False, respuesta(False, f'No hay una elecci\u00f3n activa. No se puede {mensaje_accion}.', codigo=400)
    if eleccion['estado'] != ESTADO_INSCRIPCIONES_ABIERTAS:
        return False, respuesta(False, f'La elecci\u00f3n debe estar en per\u00edodo de inscripciones para {mensaje_accion}. Estado actual: {eleccion["estado"]}', codigo=400)
    return True, None


def _validar_no_en_votacion(mensaje_accion="realizar esta operaci\u00f3n"):
    """Verifica que la elección activa NO esté en EN_VOTACION."""
    eleccion = ejecutar_consulta(
        "SELECT id_eleccion, estado FROM elecciones WHERE activa = 1 LIMIT 1",
        una_fila=True)
    if eleccion and eleccion['estado'] == ESTADO_EN_VOTACION:
        return False, respuesta(False, f'No se pudo {mensaje_accion} porque la elecci\u00f3n est\u00e1 en per\u00edodo de votaci\u00f3n.', codigo=400)
    return True, None


@elecciones_bp.route('', methods=['POST'])
@token_requerido
def crear_eleccion():
    """Crea una nueva elección."""
    datos = request.get_json(silent=True) or {}
    if not datos.get('nombreEleccion'):
        return respuesta(False, 'Nombre de elección requerido', codigo=400)

    activa_existente = ejecutar_consulta(
        "SELECT id_eleccion FROM elecciones WHERE activa = 1 LIMIT 1", una_fila=True)
    if activa_existente:
        return respuesta(False, 'Ya existe una elecci\u00f3n activa. No se puede registrar otra.', codigo=409)

    # Validar que los campos de hora tengan formato adecuado
    campos_hora = ['horaInicioInscripcion', 'horaFinInscripcion', 'horaInicioVotacion', 'horaFinVotacion']
    for campo in campos_hora:
        v = datos.get(campo)
        if v and isinstance(v, str) and v.count(':') != 2:
            return respuesta(False, f'Formato de hora inv\u00e1lido en {campo}: {v}', codigo=400)

    estado = _calcular_estado_auto(
        datos.get('fechaInicioInscripcion'), datos.get('horaInicioInscripcion'),
        datos.get('fechaCierreInscripcion'), datos.get('horaFinInscripcion'),
        datos.get('fechaVotacion'), datos.get('horaInicioVotacion'), datos.get('horaFinVotacion'))

    from zoneinfo import ZoneInfo
    tz_lima = ZoneInfo('America/Lima')
    ahora = datetime.now(tz_lima).strftime('%Y-%m-%d %H:%M:%S')

    sql = """INSERT INTO elecciones (nombre_eleccion, fecha_inicio_inscripcion, fecha_cierre_inscripcion,
              hora_inicio_inscripcion, hora_fin_inscripcion, fecha_votacion, hora_inicio_votacion,
              hora_fin_votacion, estado, activa, descripcion, fecha_creacion)
             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        datos['nombreEleccion'],
        datos.get('fechaInicioInscripcion') or None,
        datos.get('fechaCierreInscripcion') or None,
        datos.get('horaInicioInscripcion') or None,
        datos.get('horaFinInscripcion') or None,
        datos.get('fechaVotacion') or None,
        datos.get('horaInicioVotacion') or None,
        datos.get('horaFinVotacion') or None,
        estado,
        1 if datos.get('activa') in ('1', 1) else 0,
        datos.get('descripcion', ''),
        ahora
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear la elección', codigo=500)

    if datos.get('activa') in ('1', 1):
        ejecutar_consulta("UPDATE elecciones SET activa = 0 WHERE id_eleccion != %s", (nuevo_id,))

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'ELECCIONES', 'CREAR',
                        f"Elección creada: {datos['nombreEleccion']}")
    return respuesta(True, 'Elección creada exitosamente', {'idEleccion': nuevo_id})

@elecciones_bp.route('/<int:id_eleccion>', methods=['PUT'])
@token_requerido
def actualizar_eleccion(id_eleccion):
    """Actualiza una elección existente."""
    existente = ejecutar_consulta(
        "SELECT id_eleccion FROM elecciones WHERE id_eleccion = %s", (id_eleccion,), una_fila=True)
    if not existente:
        return respuesta(False, 'Elección no encontrada', codigo=404)

    datos = request.get_json(silent=True) or {}

    estado = _calcular_estado_auto(
        datos.get('fechaInicioInscripcion'), datos.get('horaInicioInscripcion'),
        datos.get('fechaCierreInscripcion'), datos.get('horaFinInscripcion'),
        datos.get('fechaVotacion'), datos.get('horaInicioVotacion'), datos.get('horaFinVotacion'))

    sql = """UPDATE elecciones SET nombre_eleccion = %s, fecha_inicio_inscripcion = %s,
              fecha_cierre_inscripcion = %s, hora_inicio_inscripcion = %s, hora_fin_inscripcion = %s,
              fecha_votacion = %s, hora_inicio_votacion = %s, hora_fin_votacion = %s,
              estado = %s, activa = %s, descripcion = %s
             WHERE id_eleccion = %s"""
    ejecutar_consulta(sql, (
        datos.get('nombreEleccion', ''),
        datos.get('fechaInicioInscripcion') or None,
        datos.get('fechaCierreInscripcion') or None,
        datos.get('horaInicioInscripcion') or None,
        datos.get('horaFinInscripcion') or None,
        datos.get('fechaVotacion') or None,
        datos.get('horaInicioVotacion') or None,
        datos.get('horaFinVotacion') or None,
        estado,
        1 if datos.get('activa') in ('1', 1) else 0,
        datos.get('descripcion', ''),
        id_eleccion
    ))

    if datos.get('activa') in ('1', 1):
        ejecutar_consulta("UPDATE elecciones SET activa = 0 WHERE id_eleccion != %s", (id_eleccion,))

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'ELECCIONES', 'ACTUALIZAR',
                        f"Elección ID {id_eleccion} actualizada")
    return respuesta(True, 'Elección actualizada exitosamente')


# ---------------------------------------------------------------------------
# 6.05 CASERÍOS  /api/caserios
# ---------------------------------------------------------------------------
caserios_bp = Blueprint('caserios', __name__, url_prefix='/api/caserios')


@caserios_bp.route('', methods=['GET'])
@token_requerido
def listar_caserios():
    """Lista caseríos con paginación y búsqueda."""
    pagina, por_pagina, offset = obtener_paginacion()
    busqueda = request.args.get('busqueda', '').strip()

    sql_base = "FROM caserios"
    params = []
    if busqueda:
        sql_base += " WHERE nombre_caserio LIKE %s"
        params = [f"%{busqueda}%"]

    total_row = ejecutar_consulta(f"SELECT COUNT(*) cantidad {sql_base}", params, una_fila=True)
    total = total_row['cantidad'] if total_row else 0

    sql_datos = f"""SELECT id_caserio, nombre_caserio, descripcion, activo
                    {sql_base} ORDER BY id_caserio ASC LIMIT %s OFFSET %s"""
    lista = ejecutar_consulta(sql_datos, params + [por_pagina, offset])

    datos = []
    if lista:
        for c in lista:
            datos.append({
                'idCaserio': c['id_caserio'],
                'nombreCaserio': c['nombre_caserio'],
                'descripcion': c.get('descripcion', ''),
                'activo': bool(c.get('activo', 0))
            })
    return respuesta_paginada(datos, total, pagina, por_pagina)


@caserios_bp.route('/activos', methods=['GET'])
@token_requerido
def listar_caserios_activos():
    """Lista todos los caseríos activos sin paginación."""
    lista = ejecutar_consulta(
        "SELECT id_caserio, nombre_caserio, descripcion FROM caserios WHERE activo = 1 ORDER BY nombre_caserio")
    datos = []
    if lista:
        for c in lista:
            datos.append({
                'idCaserio': c['id_caserio'],
                'nombreCaserio': c['nombre_caserio'],
                'descripcion': c.get('descripcion', '')
            })
    return respuesta(True, '', datos)


@caserios_bp.route('/<int:id_caserio>', methods=['GET'])
@token_requerido
def obtener_caserio(id_caserio):
    """Obtiene un caserío por su ID."""
    caserio = ejecutar_consulta(
        "SELECT id_caserio, nombre_caserio, descripcion, activo FROM caserios WHERE id_caserio = %s",
        (id_caserio,), una_fila=True)
    if not caserio:
        return respuesta(False, 'Caserío no encontrado', codigo=404)

    datos = {
        'idCaserio': caserio['id_caserio'],
        'nombreCaserio': caserio['nombre_caserio'],
        'descripcion': caserio.get('descripcion', ''),
        'activo': bool(caserio.get('activo', 0))
    }
    return respuesta(True, '', datos)


@caserios_bp.route('', methods=['POST'])
@token_requerido
def crear_caserio():
    """Crea un nuevo caserío."""
    ok, err = _validar_no_en_votacion("crear caser\u00edos")
    if not ok:
        return err
    datos = request.get_json(silent=True) or {}
    if not datos.get('nombreCaserio'):
        return respuesta(False, 'Nombre de caserío requerido', codigo=400)

    sql = "INSERT INTO caserios (nombre_caserio, descripcion) VALUES (%s, %s)"
    nuevo_id = ejecutar_consulta(sql, (
        datos['nombreCaserio'], datos.get('descripcion', '')
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear el caserío', codigo=500)

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'CASERIOS', 'CREAR',
                        f"Caserío creado: {datos['nombreCaserio']}")
    return respuesta(True, 'Caserío creado exitosamente', {'idCaserio': nuevo_id})


@caserios_bp.route('/<int:id_caserio>', methods=['PUT'])
@token_requerido
def actualizar_caserio(id_caserio):
    """Actualiza un caserío existente."""
    ok, err = _validar_no_en_votacion("editar caser\u00edos")
    if not ok:
        return err
    existente = ejecutar_consulta(
        "SELECT id_caserio FROM caserios WHERE id_caserio = %s", (id_caserio,), una_fila=True)
    if not existente:
        return respuesta(False, 'Caserío no encontrado', codigo=404)

    datos = request.get_json(silent=True) or {}
    sql = "UPDATE caserios SET nombre_caserio = %s, descripcion = %s WHERE id_caserio = %s"
    ejecutar_consulta(sql, (datos.get('nombreCaserio', ''), datos.get('descripcion', ''), id_caserio))

    return respuesta(True, 'Caserío actualizado exitosamente')


@caserios_bp.route('/<int:id_caserio>/estado', methods=['PATCH', 'POST'])
@token_requerido
def cambiar_estado_caserio(id_caserio):
    """Activa o desactiva un caserío."""
    datos = request.get_json(silent=True) or {}
    activo = 1 if datos.get('activo') else 0
    if not activo:
        ok, err = _validar_no_en_votacion("desactivar caser\u00edos")
        if not ok:
            return err
    ejecutar_consulta("UPDATE caserios SET activo = %s WHERE id_caserio = %s", (activo, id_caserio))
    return respuesta(True, 'Estado actualizado')


# ---------------------------------------------------------------------------
# 6.06 LOCALES DE VOTACIÓN  /api/locales-votacion
# ---------------------------------------------------------------------------
locales_bp = Blueprint('locales', __name__, url_prefix='/api/locales-votacion')


@locales_bp.route('', methods=['GET'])
@token_requerido
def listar_locales():
    """Lista locales de votación con paginación y búsqueda."""
    pagina, por_pagina, offset = obtener_paginacion()
    busqueda = request.args.get('busqueda', '').strip()

    sql_base = """FROM locales_votacion l INNER JOIN caserios c ON l.id_caserio = c.id_caserio"""
    params = []
    if busqueda:
        sql_base += " WHERE l.nombre_local LIKE %s"
        params = [f"%{busqueda}%"]

    total_row = ejecutar_consulta(f"SELECT COUNT(*) cantidad {sql_base}", params, una_fila=True)
    total = total_row['cantidad'] if total_row else 0

    sql_datos = f"""SELECT l.id_local_votacion, l.id_caserio, c.nombre_caserio, l.nombre_local,
                           l.direccion, l.referencia, l.activo
                    {sql_base} ORDER BY l.id_local_votacion ASC LIMIT %s OFFSET %s"""
    lista = ejecutar_consulta(sql_datos, params + [por_pagina, offset])

    datos = []
    if lista:
        for l in lista:
            datos.append({
                'idLocalVotacion': l['id_local_votacion'],
                'idCaserio': l['id_caserio'],
                'nombreCaserio': l['nombre_caserio'],
                'nombreLocal': l['nombre_local'],
                'direccion': l.get('direccion', ''),
                'referencia': l.get('referencia', ''),
                'activo': bool(l.get('activo', 0))
            })
    return respuesta_paginada(datos, total, pagina, por_pagina)


@locales_bp.route('/activos', methods=['GET'])
@token_requerido
def listar_locales_activos():
    """Lista locales de votación activos, opcionalmente por caserío."""
    id_caserio = request.args.get('idCaserio', type=int)
    if id_caserio:
        sql = """SELECT l.id_local_votacion, l.id_caserio, c.nombre_caserio, l.nombre_local,
                        l.direccion, l.referencia
                 FROM locales_votacion l
                 INNER JOIN caserios c ON l.id_caserio = c.id_caserio
                 WHERE l.activo = 1 AND l.id_caserio = %s
                 ORDER BY l.nombre_local"""
        lista = ejecutar_consulta(sql, (id_caserio,))
    else:
        sql = """SELECT l.id_local_votacion, l.id_caserio, c.nombre_caserio, l.nombre_local,
                        l.direccion, l.referencia
                 FROM locales_votacion l
                 INNER JOIN caserios c ON l.id_caserio = c.id_caserio
                 WHERE l.activo = 1
                 ORDER BY c.nombre_caserio, l.nombre_local"""
        lista = ejecutar_consulta(sql)

    datos = []
    if lista:
        for l in lista:
            datos.append({
                'idLocalVotacion': l['id_local_votacion'],
                'idCaserio': l['id_caserio'],
                'nombreCaserio': l['nombre_caserio'],
                'nombreLocal': l['nombre_local'],
                'direccion': l.get('direccion', ''),
                'referencia': l.get('referencia', '')
            })
    return respuesta(True, '', datos)


@locales_bp.route('/<int:id_local>', methods=['GET'])
@token_requerido
def obtener_local(id_local):
    """Obtiene un local de votación por su ID."""
    sql = """SELECT l.id_local_votacion, l.id_caserio, c.nombre_caserio, l.nombre_local,
                    l.direccion, l.referencia, l.activo
             FROM locales_votacion l
             INNER JOIN caserios c ON l.id_caserio = c.id_caserio
             WHERE l.id_local_votacion = %s"""
    local = ejecutar_consulta(sql, (id_local,), una_fila=True)
    if not local:
        return respuesta(False, 'Local de votación no encontrado', codigo=404)

    datos = {
        'idLocalVotacion': local['id_local_votacion'],
        'idCaserio': local['id_caserio'],
        'nombreCaserio': local['nombre_caserio'],
        'nombreLocal': local['nombre_local'],
        'direccion': local.get('direccion', ''),
        'referencia': local.get('referencia', ''),
        'activo': bool(local.get('activo', 0))
    }
    return respuesta(True, '', datos)


@locales_bp.route('', methods=['POST'])
@token_requerido
def crear_local():
    """Crea un nuevo local de votación."""
    ok, err = _validar_no_en_votacion("crear locales de votaci\u00f3n")
    if not ok:
        return err
    datos = request.get_json(silent=True) or {}
    if not datos.get('nombreLocal') or not datos.get('idCaserio'):
        return respuesta(False, 'Nombre del local y caserío requeridos', codigo=400)

    sql = """INSERT INTO locales_votacion (id_caserio, nombre_local, direccion, referencia)
             VALUES (%s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        datos['idCaserio'], datos['nombreLocal'],
        datos.get('direccion', ''), datos.get('referencia', '')
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear el local', codigo=500)

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'LOCALES', 'CREAR',
                        f"Local creado: {datos['nombreLocal']}")
    return respuesta(True, 'Local de votación creado exitosamente', {'idLocalVotacion': nuevo_id})


@locales_bp.route('/<int:id_local>', methods=['PUT'])
@token_requerido
def actualizar_local(id_local):
    """Actualiza un local de votación."""
    ok, err = _validar_no_en_votacion("editar locales de votaci\u00f3n")
    if not ok:
        return err
    existente = ejecutar_consulta(
        "SELECT id_local_votacion FROM locales_votacion WHERE id_local_votacion = %s",
        (id_local,), una_fila=True)
    if not existente:
        return respuesta(False, 'Local no encontrado', codigo=404)

    datos = request.get_json(silent=True) or {}
    sql = """UPDATE locales_votacion SET id_caserio = %s, nombre_local = %s,
              direccion = %s, referencia = %s WHERE id_local_votacion = %s"""
    ejecutar_consulta(sql, (
        datos.get('idCaserio'), datos.get('nombreLocal', ''),
        datos.get('direccion', ''), datos.get('referencia', ''), id_local
    ))
    return respuesta(True, 'Local de votación actualizado')


@locales_bp.route('/<int:id_local>/estado', methods=['PATCH', 'POST'])
@token_requerido
def cambiar_estado_local(id_local):
    """Activa o desactiva un local de votación."""
    datos = request.get_json(silent=True) or {}
    activo = 1 if datos.get('activo') else 0
    if not activo:
        ok, err = _validar_no_en_votacion("desactivar locales de votaci\u00f3n")
        if not ok:
            return err
    ejecutar_consulta("UPDATE locales_votacion SET activo = %s WHERE id_local_votacion = %s", (activo, id_local))
    return respuesta(True, 'Estado actualizado')


# ---------------------------------------------------------------------------
# 6.07 MESAS DE SUFRAGIO  /api/mesas-sufragio
# ---------------------------------------------------------------------------
mesas_bp = Blueprint('mesas', __name__, url_prefix='/api/mesas-sufragio')


@mesas_bp.route('', methods=['GET'])
@token_requerido
def listar_mesas():
    """Lista mesas de sufragio con paginación y búsqueda."""
    pagina, por_pagina, offset = obtener_paginacion()
    busqueda = request.args.get('busqueda', '').strip()

    sql_base = """FROM mesas_sufragio m
                  INNER JOIN locales_votacion l ON m.id_local_votacion = l.id_local_votacion
                  INNER JOIN caserios c ON m.id_caserio = c.id_caserio"""
    params = []
    if busqueda:
        sql_base += " WHERE m.codigo_mesa LIKE %s OR c.nombre_caserio LIKE %s"
        like = f"%{busqueda}%"
        params = [like, like]

    total_row = ejecutar_consulta(f"SELECT COUNT(*) cantidad {sql_base}", params, una_fila=True)
    total = total_row['cantidad'] if total_row else 0

    sql_datos = f"""SELECT m.id_mesa_sufragio, m.codigo_mesa, m.id_local_votacion, l.nombre_local,
                           m.id_caserio, c.nombre_caserio, m.capacidad_maxima, m.activo
                    {sql_base} ORDER BY m.id_mesa_sufragio ASC LIMIT %s OFFSET %s"""
    lista = ejecutar_consulta(sql_datos, params + [por_pagina, offset])

    datos = []
    if lista:
        for m in lista:
            datos.append({
                'idMesaSufragio': m['id_mesa_sufragio'],
                'codigoMesa': m['codigo_mesa'],
                'idLocalVotacion': m['id_local_votacion'],
                'nombreLocal': m['nombre_local'],
                'idCaserio': m['id_caserio'],
                'nombreCaserio': m['nombre_caserio'],
                'capacidadMaxima': m.get('capacidad_maxima', 0),
                'activo': bool(m.get('activo', 0))
            })
    return respuesta_paginada(datos, total, pagina, por_pagina)


@mesas_bp.route('/activas', methods=['GET'])
def listar_mesas_activas():
    """Lista mesas activas, opcionalmente por caserío."""
    id_caserio = request.args.get('idCaserio', type=int)
    if id_caserio:
        sql = """SELECT m.id_mesa_sufragio, m.codigo_mesa, m.id_local_votacion, l.nombre_local,
                        m.id_caserio, c.nombre_caserio
                 FROM mesas_sufragio m
                 INNER JOIN locales_votacion l ON m.id_local_votacion = l.id_local_votacion
                 INNER JOIN caserios c ON m.id_caserio = c.id_caserio
                 WHERE m.activo = 1 AND m.id_caserio = %s
                 ORDER BY m.codigo_mesa"""
        lista = ejecutar_consulta(sql, (id_caserio,))
    else:
        sql = """SELECT m.id_mesa_sufragio, m.codigo_mesa, m.id_local_votacion, l.nombre_local,
                        m.id_caserio, c.nombre_caserio
                 FROM mesas_sufragio m
                 INNER JOIN locales_votacion l ON m.id_local_votacion = l.id_local_votacion
                 INNER JOIN caserios c ON m.id_caserio = c.id_caserio
                 WHERE m.activo = 1
                 ORDER BY c.nombre_caserio, m.codigo_mesa"""
        lista = ejecutar_consulta(sql)

    datos = []
    if lista:
        for m in lista:
            datos.append({
                'idMesaSufragio': m['id_mesa_sufragio'],
                'codigoMesa': m['codigo_mesa'],
                'idLocalVotacion': m['id_local_votacion'],
                'nombreLocal': m['nombre_local'],
                'idCaserio': m['id_caserio'],
                'nombreCaserio': m['nombre_caserio']
            })
    return respuesta(True, '', datos)


@mesas_bp.route('/primera-por-caserio/<int:id_caserio>', methods=['GET'])
@token_requerido
def primera_mesa_por_caserio(id_caserio):
    """Obtiene la primera mesa activa de un caserío."""
    sql = """SELECT id_local_votacion, id_mesa_sufragio, codigo_mesa
             FROM mesas_sufragio
             WHERE id_caserio = %s AND activo = 1
             ORDER BY id_mesa_sufragio LIMIT 1"""
    mesa = ejecutar_consulta(sql, (id_caserio,), una_fila=True)
    if not mesa:
        return respuesta(False, 'No hay mesas activas para este caserío', codigo=404)

    datos = {
        'idLocalVotacion': mesa['id_local_votacion'],
        'idMesaSufragio': mesa['id_mesa_sufragio'],
        'codigoMesa': mesa['codigo_mesa']
    }
    return respuesta(True, '', datos)


@mesas_bp.route('/<int:id_mesa>', methods=['GET'])
@token_requerido
def obtener_mesa(id_mesa):
    """Obtiene una mesa de sufragio por su ID."""
    sql = """SELECT m.id_mesa_sufragio, m.codigo_mesa, m.id_local_votacion, l.nombre_local,
                    m.id_caserio, c.nombre_caserio, m.capacidad_maxima, m.activo
             FROM mesas_sufragio m
             INNER JOIN locales_votacion l ON m.id_local_votacion = l.id_local_votacion
             INNER JOIN caserios c ON m.id_caserio = c.id_caserio
             WHERE m.id_mesa_sufragio = %s"""
    mesa = ejecutar_consulta(sql, (id_mesa,), una_fila=True)
    if not mesa:
        return respuesta(False, 'Mesa no encontrada', codigo=404)

    datos = {
        'idMesaSufragio': mesa['id_mesa_sufragio'],
        'codigoMesa': mesa['codigo_mesa'],
        'idLocalVotacion': mesa['id_local_votacion'],
        'nombreLocal': mesa['nombre_local'],
        'idCaserio': mesa['id_caserio'],
        'nombreCaserio': mesa['nombre_caserio'],
        'capacidadMaxima': mesa.get('capacidad_maxima', 0),
        'activo': bool(mesa.get('activo', 0))
    }
    return respuesta(True, '', datos)


@mesas_bp.route('', methods=['POST'])
@token_requerido
def crear_mesa():
    """Crea una nueva mesa de sufragio."""
    ok, err = _validar_no_en_votacion("crear mesas de sufragio")
    if not ok:
        return err
    datos = request.get_json(silent=True) or {}
    if not datos.get('codigoMesa') or not datos.get('idLocalVotacion') or not datos.get('idCaserio'):
        return respuesta(False, 'Código, local y caserío requeridos', codigo=400)

    from zoneinfo import ZoneInfo
    tz_lima = ZoneInfo('America/Lima')
    ahora = datetime.now(tz_lima).strftime('%Y-%m-%d %H:%M:%S')
    sql = """INSERT INTO mesas_sufragio (codigo_mesa, id_local_votacion, id_caserio, capacidad_maxima, fecha_creacion)
             VALUES (%s, %s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        datos['codigoMesa'], datos['idLocalVotacion'], datos['idCaserio'],
        datos.get('capacidadMaxima', 0), ahora
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear la mesa', codigo=500)

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'MESAS', 'CREAR',
                        f"Mesa creada: {datos['codigoMesa']}")
    return respuesta(True, 'Mesa de sufragio creada exitosamente', {'idMesaSufragio': nuevo_id})


@mesas_bp.route('/<int:id_mesa>', methods=['PUT'])
@token_requerido
def actualizar_mesa(id_mesa):
    """Actualiza una mesa de sufragio."""
    ok, err = _validar_no_en_votacion("editar mesas de sufragio")
    if not ok:
        return err
    existente = ejecutar_consulta(
        "SELECT id_mesa_sufragio FROM mesas_sufragio WHERE id_mesa_sufragio = %s",
        (id_mesa,), una_fila=True)
    if not existente:
        return respuesta(False, 'Mesa no encontrada', codigo=404)

    datos = request.get_json(silent=True) or {}
    sql = """UPDATE mesas_sufragio SET codigo_mesa = %s, id_local_votacion = %s, id_caserio = %s,
              capacidad_maxima = %s
             WHERE id_mesa_sufragio = %s"""
    ejecutar_consulta(sql, (
        datos.get('codigoMesa', ''), datos.get('idLocalVotacion'), datos.get('idCaserio'),
        datos.get('capacidadMaxima', 0), id_mesa
    ))
    return respuesta(True, 'Mesa actualizada exitosamente')


@mesas_bp.route('/<int:id_mesa>/estado', methods=['PATCH', 'POST'])
@token_requerido
def cambiar_estado_mesa(id_mesa):
    """Activa o desactiva una mesa."""
    datos = request.get_json(silent=True) or {}
    activo = 1 if datos.get('activo') else 0
    if not activo:
        ok, err = _validar_no_en_votacion("desactivar mesas de sufragio")
        if not ok:
            return err
    ejecutar_consulta("UPDATE mesas_sufragio SET activo = %s WHERE id_mesa_sufragio = %s", (activo, id_mesa))
    return respuesta(True, 'Estado actualizado')


# ---------------------------------------------------------------------------
# 6.08 COMUNEROS  /api/comuneros
# ---------------------------------------------------------------------------
comuneros_bp = Blueprint('comuneros', __name__, url_prefix='/api/comuneros')


@comuneros_bp.route('', methods=['GET'])
@token_requerido
def listar_comuneros():
    """Lista comuneros con paginación, búsqueda y filtro por caserío."""
    pagina, por_pagina, offset = obtener_paginacion()
    busqueda = request.args.get('busqueda', '').strip()
    id_caserio = request.args.get('idCaserio', type=int)

    condiciones = []
    params = []

    if busqueda:
        condiciones.append(
            "(c.dni LIKE %s OR c.nombres LIKE %s OR c.apellidos LIKE %s OR c.codigo_personal LIKE %s)")
        like = f"%{busqueda}%"
        params.extend([like, like, like, like])

    if id_caserio:
        condiciones.append("c.id_caserio = %s")
        params.append(id_caserio)

    where = "WHERE " + " AND ".join(condiciones) if condiciones else ""

    sql_base = f"""FROM comuneros c
                   LEFT JOIN caserios ca ON c.id_caserio = ca.id_caserio
                   LEFT JOIN mesas_sufragio m ON c.id_mesa_sufragio = m.id_mesa_sufragio
                   {where}"""

    total_row = ejecutar_consulta(f"SELECT COUNT(*) cantidad {sql_base}", params, una_fila=True)
    total = total_row['cantidad'] if total_row else 0

    sql_datos = f"""SELECT c.id_comunero, c.dni, c.nombres, c.apellidos, c.estado,
                           c.codigo_personal, c.id_caserio, ca.nombre_caserio,
                           c.id_mesa_sufragio, m.codigo_mesa
                    {sql_base}
                    ORDER BY ca.nombre_caserio ASC, c.id_mesa_sufragio ASC, c.apellidos ASC, c.nombres ASC
                    LIMIT %s OFFSET %s"""
    lista = ejecutar_consulta(sql_datos, params + [por_pagina, offset])

    datos = []
    if lista:
        for c in lista:
            datos.append({
                'idComunero': c['id_comunero'],
                'dni': c['dni'],
                'nombres': c['nombres'],
                'apellidos': c['apellidos'],
                'estado': c['estado'],
                'codigoPersonal': c.get('codigo_personal', ''),
                'idCaserio': c.get('id_caserio'),
                'nombreCaserio': c.get('nombre_caserio', ''),
                'idMesaSufragio': c.get('id_mesa_sufragio'),
                'codigoMesa': c.get('codigo_mesa', '')
            })
    return respuesta_paginada(datos, total, pagina, por_pagina)


@comuneros_bp.route('/<int:id_comunero>', methods=['GET'])
@token_requerido
def obtener_comunero(id_comunero):
    """Obtiene un comunero por su ID con todos los detalles."""
    sql = """SELECT id_comunero, dni, nombres, apellidos, fecha_nacimiento, sexo, telefono,
                    direccion, id_caserio, id_local_votacion, id_mesa_sufragio, estado,
                    codigo_personal, clave_votacion_hash,
                    fecha_registro, fecha_actualizacion
             FROM comuneros WHERE id_comunero = %s"""
    comunero = ejecutar_consulta(sql, (id_comunero,), una_fila=True)
    if not comunero:
        return respuesta(False, 'Comunero no encontrado', codigo=404)

    datos = {
        'idComunero': comunero['id_comunero'],
        'dni': comunero['dni'],
        'nombres': comunero['nombres'],
        'apellidos': comunero['apellidos'],
        'fechaNacimiento': str(comunero.get('fecha_nacimiento', '')) if comunero.get('fecha_nacimiento') else '',
        'sexo': comunero.get('sexo', ''),
        'telefono': comunero.get('telefono', ''),
        'direccion': comunero.get('direccion', ''),
        'idCaserio': comunero.get('id_caserio'),
        'idLocalVotacion': comunero.get('id_local_votacion'),
        'idMesaSufragio': comunero.get('id_mesa_sufragio'),
        'estado': comunero['estado'],
        'codigoPersonal': comunero.get('codigo_personal', ''),
        'fechaRegistro': str(comunero.get('fecha_registro', '')) if comunero.get('fecha_registro') else '',
        'fechaActualizacion': str(comunero.get('fecha_actualizacion', '')) if comunero.get('fecha_actualizacion') else ''
    }
    return respuesta(True, '', datos)


@comuneros_bp.route('/verificar-dni/<dni>', methods=['GET'])
@token_requerido
def verificar_dni_comunero(dni):
    """Verifica si un DNI ya está registrado."""
    row = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM comuneros WHERE dni = %s", (dni,), una_fila=True)
    existe = row['cantidad'] > 0 if row else False
    return respuesta(True, '', {'existe': existe})


@comuneros_bp.route('', methods=['POST'])
@token_requerido
def crear_comunero():
    """Crea un nuevo comunero con código personal y clave de votación."""
    ok, err = _validar_no_en_votacion("crear comuneros")
    if not ok:
        return err
    datos = request.get_json(silent=True) or {}
    campos_requeridos = ['dni', 'nombres', 'apellidos']
    for campo in campos_requeridos:
        if not datos.get(campo):
            return respuesta(False, f"El campo '{campo}' es requerido", codigo=400)

    # Verificar DNI único
    existe_dni = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM comuneros WHERE dni = %s", (datos['dni'],), una_fila=True)
    if existe_dni and existe_dni['cantidad'] > 0:
        return respuesta(False, 'Ya existe un comunero con ese DNI', codigo=409)

    codigo_personal = f"CC-{datos['dni']}"
    clave_votacion = datos.get('claveVotacion')
    if not clave_votacion or not (isinstance(clave_votacion, str) and len(clave_votacion) == 6 and clave_votacion.isdigit()):
        clave_votacion = generar_clave_votacion()
    clave_hash = encriptar_contrasena(clave_votacion)

    # Si no se envía idLocalVotacion, obtenerlo desde la mesa de sufragio
    id_local_votacion = datos.get('idLocalVotacion')
    if not id_local_votacion and datos.get('idMesaSufragio'):
        mesa_row = ejecutar_consulta(
            "SELECT id_local_votacion FROM mesas_sufragio WHERE id_mesa_sufragio = %s",
            (datos['idMesaSufragio'],), una_fila=True)
        id_local_votacion = mesa_row['id_local_votacion'] if mesa_row else None

    from zoneinfo import ZoneInfo
    tz_lima = ZoneInfo('America/Lima')
    ahora = datetime.now(tz_lima).strftime('%Y-%m-%d %H:%M:%S')

    sql = """INSERT INTO comuneros (dni, nombres, apellidos, fecha_nacimiento, sexo, telefono,
              direccion, id_caserio, id_local_votacion, id_mesa_sufragio, estado, codigo_personal,
              clave_votacion_hash, fecha_registro, fecha_actualizacion)
             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        datos['dni'], datos['nombres'], datos['apellidos'],
        datos.get('fechaNacimiento') or None, datos.get('sexo', ''),
        datos.get('telefono', ''), datos.get('direccion', ''),
        datos.get('idCaserio'), id_local_votacion,
        datos.get('idMesaSufragio'), 1,  # estado = 1 (activo)
        codigo_personal, clave_hash,
        ahora, ahora  # fecha_registro, fecha_actualizacion
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear el comunero', codigo=500)

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'COMUNEROS', 'CREAR',
                        f"Comunero creado: {datos['nombres']} {datos['apellidos']}")

    return respuesta(True, 'Comunero creado exitosamente', {
        'idComunero': nuevo_id,
        'codigoPersonal': codigo_personal,
        'claveVotacion': clave_votacion
    })


@comuneros_bp.route('/<int:id_comunero>', methods=['PUT'])
@token_requerido
def actualizar_comunero(id_comunero):
    """Actualiza un comunero existente."""
    ok, err = _validar_no_en_votacion("editar comuneros")
    if not ok:
        return err
    existente = ejecutar_consulta(
        "SELECT id_comunero FROM comuneros WHERE id_comunero = %s", (id_comunero,), una_fila=True)
    if not existente:
        return respuesta(False, 'Comunero no encontrado', codigo=404)

    datos = request.get_json(silent=True) or {}

    # Si no se envía idLocalVotacion, obtenerlo desde la mesa de sufragio
    id_local_votacion = datos.get('idLocalVotacion')
    if not id_local_votacion and datos.get('idMesaSufragio'):
        mesa_row = ejecutar_consulta(
            "SELECT id_local_votacion FROM mesas_sufragio WHERE id_mesa_sufragio = %s",
            (datos['idMesaSufragio'],), una_fila=True)
        id_local_votacion = mesa_row['id_local_votacion'] if mesa_row else None

    from zoneinfo import ZoneInfo
    tz_lima = ZoneInfo('America/Lima')
    ahora = datetime.now(tz_lima).strftime('%Y-%m-%d %H:%M:%S')

    sql = """UPDATE comuneros SET nombres = %s, apellidos = %s, fecha_nacimiento = %s,
              sexo = %s, telefono = %s, direccion = %s, id_caserio = %s,
              id_local_votacion = %s, id_mesa_sufragio = %s, estado = %s,
              fecha_actualizacion = %s
             WHERE id_comunero = %s"""
    ejecutar_consulta(sql, (
        datos.get('nombres', ''), datos.get('apellidos', ''),
        datos.get('fechaNacimiento') or None, datos.get('sexo', ''),
        datos.get('telefono', ''), datos.get('direccion', ''),
        datos.get('idCaserio'), id_local_votacion,
        datos.get('idMesaSufragio'), datos.get('estado', 1),
        ahora, id_comunero
    ))

    clave_votacion = datos.get('claveVotacion')
    if clave_votacion:
        if isinstance(clave_votacion, str) and len(clave_votacion) == 6 and clave_votacion.isdigit():
            clave_hash = encriptar_contrasena(clave_votacion)
            ejecutar_consulta("UPDATE comuneros SET clave_votacion_hash = %s WHERE id_comunero = %s", (clave_hash, id_comunero))
        else:
            return respuesta(False, 'La clave de votaci\u00f3n debe tener exactamente 6 d\u00edgitos num\u00e9ricos', codigo=400)

    return respuesta(True, 'Comunero actualizado exitosamente')


@comuneros_bp.route('/<int:id_comunero>/estado', methods=['PATCH', 'POST'])
@token_requerido
def cambiar_estado_comunero(id_comunero):
    """Activa o desactiva un comunero."""
    datos = request.get_json(silent=True) or {}
    estado = datos.get('estado', 0)
    if estado == 0:
        ok, err = _validar_no_en_votacion("desactivar comuneros")
        if not ok:
            return err
    ejecutar_consulta("UPDATE comuneros SET estado = %s WHERE id_comunero = %s", (estado, id_comunero))
    return respuesta(True, 'Estado actualizado')


@comuneros_bp.route('/desactivar-todos', methods=['POST'])
@token_requerido
def desactivar_todos_comuneros():
    """Desactiva todos los comuneros y limpia las claves de votación."""
    ok, err = _validar_no_en_votacion("desactivar todos los comuneros")
    if not ok:
        return err
    ejecutar_consulta("UPDATE comuneros SET estado = 0, clave_votacion_hash = NULL WHERE estado = 1")
    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'COMUNEROS', 'DESACTIVAR TODOS',
                        'Todos los comuneros desactivados')
    return respuesta(True, 'Todos los comuneros han sido desactivados')


@comuneros_bp.route('/activar-todos', methods=['POST'])
@token_requerido
def activar_todos_comuneros():
    """Activa todos los comuneros."""
    ejecutar_consulta("UPDATE comuneros SET estado = 1 WHERE estado = 0")
    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'COMUNEROS', 'ACTIVAR TODOS',
                        'Todos los comuneros activados')
    return respuesta(True, 'Todos los comuneros han sido activados')


# ---------------------------------------------------------------------------
# 6.09 PARTIDOS  /api/partidos
# ---------------------------------------------------------------------------
partidos_bp = Blueprint('partidos', __name__, url_prefix='/api/partidos')


@partidos_bp.route('', methods=['GET'])
@token_requerido
def listar_partidos():
    """Lista partidos, opcionalmente filtrados por elección activa."""
    id_eleccion = request.args.get('idEleccion', type=int)
    if id_eleccion:
        sql = """SELECT id_partido, id_eleccion, nombre_partido, descripcion, propuestas, color, activo
                 FROM partidos WHERE id_eleccion = %s AND activo = 1 ORDER BY nombre_partido"""
        lista = ejecutar_consulta(sql, (id_eleccion,))
    else:
        sql = """SELECT p.id_partido, p.id_eleccion, e.nombre_eleccion, p.nombre_partido,
                        p.descripcion, p.propuestas, p.color, p.activo
                 FROM partidos p INNER JOIN elecciones e ON p.id_eleccion = e.id_eleccion
                 ORDER BY e.nombre_eleccion, p.nombre_partido"""
        lista = ejecutar_consulta(sql)

    datos = []
    if lista:
        for p in lista:
            datos.append({
                'idPartido': p['id_partido'],
                'idEleccion': p['id_eleccion'],
                'nombreEleccion': p.get('nombre_eleccion', ''),
                'nombrePartido': p['nombre_partido'],
                'descripcion': p.get('descripcion', ''),
                'propuestas': p.get('propuestas', ''),
                'color': p.get('color', ''),
                'activo': bool(p.get('activo', 0))
            })
    return respuesta(True, '', datos)


@partidos_bp.route('/<int:id_partido>', methods=['GET'])
@token_requerido
def obtener_partido(id_partido):
    """Obtiene un partido por su ID."""
    sql = """SELECT id_partido, id_eleccion, nombre_partido, descripcion, propuestas, color, activo
             FROM partidos WHERE id_partido = %s"""
    partido = ejecutar_consulta(sql, (id_partido,), una_fila=True)
    if not partido:
        return respuesta(False, 'Partido no encontrado', codigo=404)

    datos = {
        'idPartido': partido['id_partido'],
        'idEleccion': partido['id_eleccion'],
        'nombrePartido': partido['nombre_partido'],
        'descripcion': partido.get('descripcion', ''),
        'propuestas': partido.get('propuestas', ''),
        'color': partido.get('color', ''),
        'activo': bool(partido.get('activo', 0))
    }
    return respuesta(True, '', datos)


@partidos_bp.route('', methods=['POST'])
@token_requerido
def crear_partido():
    """Crea un nuevo partido."""
    ok, err = _validar_inscripciones_abiertas("crear partidos")
    if not ok:
        return err
    datos = request.get_json(silent=True) or {}
    if not datos.get('nombrePartido') or not datos.get('idEleccion'):
        return respuesta(False, 'Nombre del partido y elección requeridos', codigo=400)

    dup = ejecutar_consulta(
        "SELECT id_partido FROM partidos WHERE id_eleccion = %s AND nombre_partido = %s",
        (datos['idEleccion'], datos['nombrePartido']), una_fila=True)
    if dup:
        return respuesta(False, 'Ya existe un partido con ese nombre en esta elección', codigo=409)

    sql = """INSERT INTO partidos (id_eleccion, nombre_partido, descripcion, propuestas, color, fecha_creacion)
             VALUES (%s, %s, %s, %s, %s, %s)"""
    ahora = datetime.now(ZoneInfo('America/Lima')).strftime('%Y-%m-%d %H:%M:%S')
    nuevo_id = ejecutar_consulta(sql, (
        datos['idEleccion'], datos['nombrePartido'],
        datos.get('descripcion', ''), datos.get('propuestas', ''),
        datos.get('color', ''), ahora
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear el partido', codigo=500)

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'PARTIDOS', 'CREAR',
                        f"Partido creado: {datos['nombrePartido']}")
    return respuesta(True, 'Partido creado exitosamente', {'idPartido': nuevo_id})


@partidos_bp.route('/<int:id_partido>', methods=['PUT'])
@token_requerido
def actualizar_partido(id_partido):
    """Actualiza un partido existente."""
    ok, err = _validar_inscripciones_abiertas("modificar partidos")
    if not ok:
        return err
    existente = ejecutar_consulta(
        "SELECT id_partido FROM partidos WHERE id_partido = %s", (id_partido,), una_fila=True)
    if not existente:
        return respuesta(False, 'Partido no encontrado', codigo=404)

    datos = request.get_json(silent=True) or {}
    if datos.get('nombrePartido'):
        dup = ejecutar_consulta(
            "SELECT id_partido FROM partidos WHERE id_eleccion = (SELECT id_eleccion FROM partidos WHERE id_partido = %s) AND nombre_partido = %s AND id_partido != %s",
            (id_partido, datos['nombrePartido'], id_partido), una_fila=True)
        if dup:
            return respuesta(False, 'Ya existe un partido con ese nombre en esta elección', codigo=409)
    sql = """UPDATE partidos SET nombre_partido = %s, descripcion = %s, propuestas = %s, color = %s
             WHERE id_partido = %s"""
    ejecutar_consulta(sql, (
        datos.get('nombrePartido', ''), datos.get('descripcion', ''),
        datos.get('propuestas', ''), datos.get('color', ''), id_partido
    ))
    return respuesta(True, 'Partido actualizado')


@partidos_bp.route('/<int:id_partido>/estado', methods=['PATCH', 'POST'])
@token_requerido
def cambiar_estado_partido(id_partido):
    """Activa o desactiva un partido."""
    datos = request.get_json(silent=True) or {}
    activo = 1 if datos.get('activo') else 0
    if not activo:
        ok, err = _validar_no_en_votacion("desactivar partidos")
        if not ok:
            return err
    ejecutar_consulta("UPDATE partidos SET activo = %s WHERE id_partido = %s", (activo, id_partido))
    return respuesta(True, 'Estado actualizado')


# ---------------------------------------------------------------------------
# 6.10 CANDIDATOS  /api/candidatos
# ---------------------------------------------------------------------------
candidatos_bp = Blueprint('candidatos', __name__, url_prefix='/api/candidatos')


@candidatos_bp.route('', methods=['GET'])
@token_requerido
def listar_candidatos():
    """Lista candidatos de una elección activa."""
    id_eleccion = request.args.get('idEleccion', type=int)
    if not id_eleccion:
        return respuesta(False, 'ID de elección requerido', codigo=400)

    sql = """SELECT c.id_candidato, c.id_partido, p.nombre_partido, p.color color_partido,
                    c.nombres, c.apellidos, c.cargo, c.integrantes, c.imagen, c.activo
             FROM candidatos c
             INNER JOIN partidos p ON c.id_partido = p.id_partido
             WHERE p.id_eleccion = %s AND c.activo = 1 AND p.activo = 1
             ORDER BY c.id_candidato"""
    lista = ejecutar_consulta(sql, (id_eleccion,))

    datos = []
    if lista:
        import base64
        for c in lista:
            item = {
                'idCandidato': c['id_candidato'],
                'idPartido': c['id_partido'],
                'nombrePartido': c['nombre_partido'],
                'colorPartido': c.get('color_partido', ''),
                'nombres': c['nombres'],
                'apellidos': c['apellidos'],
                'cargo': c.get('cargo', ''),
                'integrantes': c.get('integrantes', '')
            }
            if c.get('imagen'):
                item['imagen'] = base64.b64encode(c['imagen']).decode('utf-8')
            else:
                item['imagen'] = None
            datos.append(item)
    return respuesta(True, '', datos)


@candidatos_bp.route('/<int:id_candidato>', methods=['GET'])
@token_requerido
def obtener_candidato(id_candidato):
    """Obtiene un candidato por su ID."""
    sql = """SELECT c.id_candidato, c.id_partido, p.nombre_partido, p.color color_partido,
                    c.nombres, c.apellidos, c.cargo, c.integrantes, c.imagen, c.activo
             FROM candidatos c
             INNER JOIN partidos p ON c.id_partido = p.id_partido
             WHERE c.id_candidato = %s"""
    candidato = ejecutar_consulta(sql, (id_candidato,), una_fila=True)
    if not candidato:
        return respuesta(False, 'Candidato no encontrado', codigo=404)

    import base64
    datos = {
        'idCandidato': candidato['id_candidato'],
        'idPartido': candidato['id_partido'],
        'nombrePartido': candidato['nombre_partido'],
        'colorPartido': candidato.get('color_partido', ''),
        'nombres': candidato['nombres'],
        'apellidos': candidato['apellidos'],
        'cargo': candidato.get('cargo', ''),
        'integrantes': candidato.get('integrantes', ''),
        'activo': bool(candidato.get('activo', 0))
    }
    if candidato.get('imagen'):
        datos['imagen'] = base64.b64encode(candidato['imagen']).decode('utf-8')
    else:
        datos['imagen'] = None
    return respuesta(True, '', datos)


@candidatos_bp.route('', methods=['POST'])
@token_requerido
def crear_candidato():
    """Crea un nuevo candidato."""
    ok, err = _validar_inscripciones_abiertas("crear candidatos")
    if not ok:
        return err
    datos = request.get_json(silent=True) or {}
    if not datos.get('nombres') or not datos.get('apellidos') or not datos.get('idPartido'):
        return respuesta(False, 'Nombres, apellidos y partido requeridos', codigo=400)

    existe = ejecutar_consulta(
        "SELECT id_candidato FROM candidatos WHERE id_partido = %s",
        (datos['idPartido'],), una_fila=True)
    if existe:
        return respuesta(False, 'Ese partido ya tiene un candidato registrado', codigo=409)

    import base64
    imagen_bytes = None
    if datos.get('imagen'):  # imagen en base64
        try:
            imagen_bytes = base64.b64decode(datos['imagen'])
        except Exception:
            pass

    sql = """INSERT INTO candidatos (id_partido, nombres, apellidos, cargo, integrantes, imagen)
             VALUES (%s, %s, %s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        datos['idPartido'], datos['nombres'], datos['apellidos'],
        datos.get('cargo', ''), datos.get('integrantes', ''), imagen_bytes
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al crear el candidato', codigo=500)

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'CANDIDATOS', 'CREAR',
                        f"Candidato creado: {datos['nombres']} {datos['apellidos']}")
    return respuesta(True, 'Candidato creado exitosamente', {'idCandidato': nuevo_id})


@candidatos_bp.route('/<int:id_candidato>', methods=['PUT'])
@token_requerido
def actualizar_candidato(id_candidato):
    """Actualiza un candidato existente."""
    ok, err = _validar_inscripciones_abiertas("modificar candidatos")
    if not ok:
        return err
    existente = ejecutar_consulta(
        "SELECT id_candidato FROM candidatos WHERE id_candidato = %s", (id_candidato,), una_fila=True)
    if not existente:
        return respuesta(False, 'Candidato no encontrado', codigo=404)

    datos = request.get_json(silent=True) or {}

    if datos.get('idPartido'):
        existe = ejecutar_consulta(
            "SELECT id_candidato FROM candidatos WHERE id_partido = %s AND id_candidato != %s",
            (datos['idPartido'], id_candidato), una_fila=True)
        if existe:
            return respuesta(False, 'Ese partido ya tiene un candidato registrado', codigo=409)

    import base64
    imagen_bytes = None
    if datos.get('imagen'):
        try:
            imagen_bytes = base64.b64decode(datos['imagen'])
        except Exception:
            pass

    if imagen_bytes is not None:
        sql = """UPDATE candidatos SET id_partido = %s, nombres = %s, apellidos = %s,
                  cargo = %s, integrantes = %s, imagen = %s WHERE id_candidato = %s"""
        ejecutar_consulta(sql, (
            datos.get('idPartido'), datos.get('nombres', ''), datos.get('apellidos', ''),
            datos.get('cargo', ''), datos.get('integrantes', ''), imagen_bytes, id_candidato
        ))
    else:
        sql = """UPDATE candidatos SET id_partido = %s, nombres = %s, apellidos = %s,
                  cargo = %s, integrantes = %s WHERE id_candidato = %s"""
        ejecutar_consulta(sql, (
            datos.get('idPartido'), datos.get('nombres', ''), datos.get('apellidos', ''),
            datos.get('cargo', ''), datos.get('integrantes', ''), id_candidato
        ))

    return respuesta(True, 'Candidato actualizado')


@candidatos_bp.route('/<int:id_candidato>/estado', methods=['PATCH', 'POST'])
@token_requerido
def cambiar_estado_candidato(id_candidato):
    """Activa o desactiva un candidato."""
    datos = request.get_json(silent=True) or {}
    activo = 1 if datos.get('activo') else 0
    if not activo:
        ok, err = _validar_no_en_votacion("desactivar candidatos")
        if not ok:
            return err
    ejecutar_consulta("UPDATE candidatos SET activo = %s WHERE id_candidato = %s", (activo, id_candidato))
    return respuesta(True, 'Estado actualizado')


# ---------------------------------------------------------------------------
# 6.11 MIEMBROS DE MESA  /api/miembros-mesa
# ---------------------------------------------------------------------------
miembros_bp = Blueprint('miembros', __name__, url_prefix='/api/miembros-mesa')


@miembros_bp.route('', methods=['GET'])
@token_requerido
def listar_miembros():
    """Lista miembros de mesa, opcionalmente por caserío."""
    id_caserio = request.args.get('idCaserio', type=int)

    sql = """SELECT m.id_miembro_mesa, m.id_comunero, c.dni dni_comunero,
                    CONCAT(c.nombres, ' ', c.apellidos) nombre_comunero,
                    m.id_caserio, ca.nombre_caserio, m.id_mesa_sufragio,
                    ms.codigo_mesa, lv.nombre_local, m.cargo, m.activo, m.fecha_asignacion
             FROM miembros_mesa m
             INNER JOIN comuneros c ON m.id_comunero = c.id_comunero
             INNER JOIN caserios ca ON m.id_caserio = ca.id_caserio
             LEFT JOIN mesas_sufragio ms ON m.id_mesa_sufragio = ms.id_mesa_sufragio
             LEFT JOIN locales_votacion lv ON ms.id_local_votacion = lv.id_local_votacion"""
    params = []
    if id_caserio:
        sql += " WHERE m.id_caserio = %s"
        params.append(id_caserio)
    sql += " ORDER BY ca.nombre_caserio ASC, ms.codigo_mesa ASC, m.cargo ASC"

    lista = ejecutar_consulta(sql, params or None)

    datos = []
    if lista:
        for m in lista:
            datos.append({
                'idMiembroMesa': m['id_miembro_mesa'],
                'idComunero': m['id_comunero'],
                'dniComunero': m['dni_comunero'],
                'nombreComunero': m['nombre_comunero'],
                'idCaserio': m['id_caserio'],
                'nombreCaserio': m['nombre_caserio'],
                'idMesaSufragio': m.get('id_mesa_sufragio'),
                'codigoMesa': m.get('codigo_mesa', ''),
                'nombreLocal': m.get('nombre_local', ''),
                'cargo': m['cargo'],
                'activo': bool(m.get('activo', 0)),
                'fechaAsignacion': str(m['fecha_asignacion']) if m.get('fecha_asignacion') else ''
            })
    return respuesta(True, '', datos)


@miembros_bp.route('/comuneros-disponibles/<int:id_caserio>', methods=['GET'])
@token_requerido
def comuneros_disponibles(id_caserio):
    """Lista comuneros disponibles para ser miembros de mesa (no asignados aún)."""
    sql = """SELECT c.id_comunero, c.dni, c.nombres, c.apellidos
             FROM comuneros c
             WHERE c.id_caserio = %s AND c.estado = 1
               AND c.id_comunero NOT IN (
                   SELECT id_comunero FROM miembros_mesa WHERE activo = 1
               )
             ORDER BY c.apellidos ASC, c.nombres ASC"""
    lista = ejecutar_consulta(sql, (id_caserio,))

    datos = []
    if lista:
        for c in lista:
            datos.append({
                'idComunero': c['id_comunero'],
                'dni': c['dni'],
                'nombres': c['nombres'],
                'apellidos': c['apellidos']
            })
    return respuesta(True, '', datos)


@miembros_bp.route('', methods=['POST'])
@token_requerido
def crear_miembro():
    """Asigna un comunero como miembro de mesa."""
    ok, err = _validar_no_en_votacion("asignar miembros de mesa")
    if not ok:
        return err
    datos = request.get_json(silent=True) or {}
    if not datos.get('idComunero') or not datos.get('idCaserio') or not datos.get('cargo'):
        return respuesta(False, 'Comunero, caserío y cargo requeridos', codigo=400)

    # Verificar que no esté ya activo como miembro
    existe = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM miembros_mesa WHERE id_comunero = %s AND activo = 1",
        (datos['idComunero'],), una_fila=True)
    if existe and existe['cantidad'] > 0:
        return respuesta(False, 'El comunero ya está asignado como miembro de mesa activo', codigo=409)

    from zoneinfo import ZoneInfo
    tz_lima = ZoneInfo('America/Lima')
    ahora = datetime.now(tz_lima).strftime('%Y-%m-%d %H:%M:%S')
    sql = """INSERT INTO miembros_mesa (id_comunero, id_caserio, id_mesa_sufragio, cargo, fecha_asignacion)
             VALUES (%s, %s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        datos['idComunero'], datos['idCaserio'],
        datos.get('idMesaSufragio'), datos['cargo'], ahora
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al asignar miembro de mesa', codigo=500)

    registrar_auditoria(g.usuario_actual.get('id_usuario'), 'MIEMBROS', 'ASIGNAR',
                        f"Miembro asignado: Comunero ID {datos['idComunero']} como {datos['cargo']}")
    return respuesta(True, 'Miembro de mesa asignado exitosamente', {'idMiembroMesa': nuevo_id})


@miembros_bp.route('/<int:id_miembro>', methods=['DELETE'])
@token_requerido
def eliminar_miembro(id_miembro):
    """Elimina un miembro de mesa."""
    ok, err = _validar_no_en_votacion("eliminar miembros de mesa")
    if not ok:
        return err
    ejecutar_consulta("DELETE FROM miembros_mesa WHERE id_miembro_mesa = %s", (id_miembro,))
    return respuesta(True, 'Miembro de mesa eliminado')


@miembros_bp.route('/conteo/<int:id_caserio>', methods=['GET'])
@token_requerido
def conteo_miembros(id_caserio):
    """Cuenta los miembros de mesa de un caserío."""
    row = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM miembros_mesa WHERE id_caserio = %s",
        (id_caserio,), una_fila=True)
    conteo = row['cantidad'] if row else 0
    return respuesta(True, '', {'total': conteo})


# ---------------------------------------------------------------------------
# 6.12 VOTACIÓN  /api/votacion
# ---------------------------------------------------------------------------
votacion_bp = Blueprint('votacion', __name__, url_prefix='/api/votacion')


@votacion_bp.route('/verificar', methods=['POST'])
def verificar_votante():
    """Verifica las credenciales de un votante (DNI + código personal + clave)."""
    datos = request.get_json(silent=True) or {}
    dni = datos.get('dni', '').strip()
    codigo_personal = datos.get('codigoPersonal', '').strip()
    clave_votacion = datos.get('claveVotacion', '').strip()

    if not dni or not codigo_personal or not clave_votacion:
        return respuesta(False, 'DNI, código personal y clave de votación requeridos', codigo=400)

    sql = """SELECT c.id_comunero, c.dni, c.nombres, c.apellidos, c.estado,
                    c.codigo_personal, c.clave_votacion_hash, c.id_mesa_sufragio,
                    m.codigo_mesa, c.id_caserio
             FROM comuneros c
             LEFT JOIN mesas_sufragio m ON c.id_mesa_sufragio = m.id_mesa_sufragio
             WHERE c.dni = %s AND c.codigo_personal = %s"""
    comunero = ejecutar_consulta(sql, (dni, codigo_personal), una_fila=True)

    if not comunero:
        return respuesta(False, 'Credenciales incorrectas. Verifique su DNI y código personal.', codigo=401)

    if comunero['estado'] != 1:
        return respuesta(False, 'Usted no está habilitado para votar en esta elección.', codigo=403)

    if not verificar_contrasena(clave_votacion, comunero['clave_votacion_hash']):
        return respuesta(False, 'Clave de votación incorrecta.', codigo=401)

    # Verificar si ya votó en la elección activa
    eleccion = ejecutar_consulta(
        "SELECT id_eleccion, nombre_eleccion, estado FROM elecciones WHERE activa = 1 LIMIT 1",
        una_fila=True)
    if not eleccion:
        return respuesta(False, 'No hay una elección activa en este momento.', codigo=400)

    if eleccion['estado'] != ESTADO_EN_VOTACION:
        return respuesta(False, f'La elección no está en fase de votación. Estado actual: {eleccion["estado"]}', codigo=400)

    voto_existente = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM votos WHERE id_comunero = %s AND id_eleccion = %s",
        (comunero['id_comunero'], eleccion['id_eleccion']), una_fila=True)
    if voto_existente and voto_existente['cantidad'] > 0:
        return respuesta(False, 'Usted ya ha emitido su voto en esta elección.', codigo=409)

    return respuesta(True, 'Credenciales verificadas correctamente', {
        'idComunero': comunero['id_comunero'],
        'dni': comunero['dni'],
        'nombres': comunero['nombres'],
        'apellidos': comunero['apellidos'],
        'idMesaSufragio': comunero.get('id_mesa_sufragio'),
        'codigoMesa': comunero.get('codigo_mesa', ''),
        'idCaserio': comunero.get('id_caserio'),
        'idEleccion': eleccion['id_eleccion'],
        'nombreEleccion': eleccion['nombre_eleccion']
    })


@votacion_bp.route('/emitir', methods=['POST'])
def emitir_voto():
    """Emite un voto para la elección activa."""
    datos = request.get_json(silent=True) or {}
    id_comunero = datos.get('idComunero')
    id_candidato = datos.get('idCandidato')  # None si es voto en blanco
    es_voto_blanco = datos.get('esVotoBlanco', False)

    if not id_comunero:
        return respuesta(False, 'ID de comunero requerido', codigo=400)

    if not es_voto_blanco and not id_candidato:
        return respuesta(False, 'Debe seleccionar un candidato o votar en blanco', codigo=400)

    # Verificar elección activa
    eleccion = ejecutar_consulta(
        "SELECT id_eleccion, estado FROM elecciones WHERE activa = 1 LIMIT 1", una_fila=True)
    if not eleccion:
        return respuesta(False, 'No hay una elección activa', codigo=400)

    if eleccion['estado'] != ESTADO_EN_VOTACION:
        return respuesta(False, 'La elección no está en fase de votación', codigo=400)

    id_eleccion = eleccion['id_eleccion']

    # Verificar que no haya votado
    voto_existente = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM votos WHERE id_comunero = %s AND id_eleccion = %s",
        (id_comunero, id_eleccion), una_fila=True)
    if voto_existente and voto_existente['cantidad'] > 0:
        return respuesta(False, 'Usted ya ha emitido su voto en esta elección', codigo=409)

    # Obtener id_partido del candidato si no es voto en blanco
    id_partido = None
    if not es_voto_blanco and id_candidato:
        candidato = ejecutar_consulta(
            "SELECT id_partido FROM candidatos WHERE id_candidato = %s", (id_candidato,), una_fila=True)
        if candidato:
            id_partido = candidato['id_partido']

    ip = obtener_ip()
    hash_integridad = generar_hash_integridad(id_eleccion, id_comunero, id_candidato or 0, es_voto_blanco, ip)

    sql = """INSERT INTO votos (id_eleccion, id_comunero, id_partido, id_candidato,
              es_voto_blanco, ip_origen, hash_integridad)
             VALUES (%s, %s, %s, %s, %s, %s, %s)"""
    nuevo_id = ejecutar_consulta(sql, (
        id_eleccion, id_comunero, id_partido, id_candidato,
        1 if es_voto_blanco else 0, ip, hash_integridad
    ), obtener_id=True)

    if not nuevo_id:
        return respuesta(False, 'Error al registrar el voto', codigo=500)

    return respuesta(True, 'Voto emitido exitosamente', {
        'idVoto': nuevo_id,
        'hashIntegridad': hash_integridad
    })


@votacion_bp.route('/candidatos/<int:id_eleccion>', methods=['GET'])
def candidatos_votacion_publica(id_eleccion):
    """Lista candidatos sin token para el módulo de votación público."""
    sql = """SELECT c.id_candidato, c.id_partido, p.nombre_partido, p.color color_partido,
                    c.nombres, c.apellidos, c.cargo, c.integrantes, c.imagen, c.activo
             FROM candidatos c
             INNER JOIN partidos p ON c.id_partido = p.id_partido
             WHERE p.id_eleccion = %s AND c.activo = 1 AND p.activo = 1
             ORDER BY c.id_candidato"""
    lista = ejecutar_consulta(sql, (id_eleccion,))
    datos = []
    if lista:
        import base64
        for c in lista:
            item = {
                'idCandidato': c['id_candidato'],
                'idPartido': c['id_partido'],
                'nombrePartido': c['nombre_partido'],
                'colorPartido': c.get('color_partido', ''),
                'nombres': c['nombres'],
                'apellidos': c['apellidos'],
                'cargo': c.get('cargo', ''),
                'integrantes': c.get('integrantes', '')
            }
            if c.get('imagen'):
                item['imagen'] = base64.b64encode(c['imagen']).decode('utf-8')
            else:
                item['imagen'] = None
            datos.append(item)
    return respuesta(True, '', datos)


# ---------------------------------------------------------------------------
# 6.13 RESULTADOS  /api/resultados
# ---------------------------------------------------------------------------
resultados_bp = Blueprint('resultados', __name__, url_prefix='/api/resultados')


@resultados_bp.route('/activa', methods=['GET'])
def resultados_activa():
    """Obtiene resultados generales de la elección activa."""
    eleccion = ejecutar_consulta(
        "SELECT id_eleccion, nombre_eleccion, fecha_inicio_inscripcion, fecha_cierre_inscripcion,"
        " hora_inicio_inscripcion, hora_fin_inscripcion, fecha_votacion,"
        " hora_inicio_votacion, hora_fin_votacion, estado FROM elecciones WHERE activa = 1 LIMIT 1",
        una_fila=True)
    if not eleccion:
        return respuesta(False, 'No hay elección activa', codigo=404)

    id_eleccion = eleccion['id_eleccion']

    # Total de votos
    total_votos = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM votos WHERE id_eleccion = %s",
        (id_eleccion,), una_fila=True)
    total = total_votos['cantidad'] if total_votos else 0

    # Votos en blanco
    blanco = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM votos WHERE id_eleccion = %s AND es_voto_blanco = 1",
        (id_eleccion,), una_fila=True)
    total_blanco = blanco['cantidad'] if blanco else 0

    # Total de comuneros habilitados
    habilitados = ejecutar_consulta(
        "SELECT COUNT(*) cantidad FROM comuneros WHERE estado = 1", una_fila=True)
    total_habilitados = habilitados['cantidad'] if habilitados else 0

    return respuesta(True, '', {
        'idEleccion': id_eleccion,
        'nombreEleccion': eleccion['nombre_eleccion'],
        'estado': _calcular_estado_auto(
            str(eleccion.get('fecha_inicio_inscripcion', '')) or None,
            eleccion.get('hora_inicio_inscripcion'),
            str(eleccion.get('fecha_cierre_inscripcion', '')) or None,
            eleccion.get('hora_fin_inscripcion'),
            str(eleccion.get('fecha_votacion', '')) or None,
            eleccion.get('hora_inicio_votacion'),
            eleccion.get('hora_fin_votacion')),
        'fechaVotacion': str(eleccion.get('fecha_votacion', '')) if eleccion.get('fecha_votacion') else '',
        'horaInicioVotacion': _fmt_hora(eleccion.get('hora_inicio_votacion')),
        'horaFinVotacion': _fmt_hora(eleccion.get('hora_fin_votacion')),
        'totalVotos': total,
        'votosBlanco': total_blanco,
        'totalHabilitados': total_habilitados,
        'porcentajeParticipacion': round((total / total_habilitados * 100), 2) if total_habilitados > 0 else 0
    })


@resultados_bp.route('/por-candidato/<int:id_eleccion>', methods=['GET'])
def resultados_por_candidato(id_eleccion):
    """Resultados detallados por candidato. Opcional ?idCaserio=X&idMesa=Y"""
    id_caserio = request.args.get('idCaserio', type=int)
    id_mesa = request.args.get('idMesa', type=int)

    where_extra = "AND v.es_voto_blanco = 0"
    params = [id_eleccion]
    if id_caserio:
        where_extra += " AND com.id_caserio = %s"
        params.append(id_caserio)
    if id_mesa:
        where_extra += " AND com.id_mesa_sufragio = %s"
        params.append(id_mesa)

    sql = f"""SELECT CONCAT(c.nombres, ' ', c.apellidos) nombre_candidato,
                    p.nombre_partido, p.color, COUNT(v.id_voto) total_votos
             FROM votos v
             INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
             INNER JOIN candidatos c ON v.id_candidato = c.id_candidato
             INNER JOIN partidos p ON c.id_partido = p.id_partido
             WHERE v.id_eleccion = %s {where_extra}
             GROUP BY c.id_candidato, c.nombres, c.apellidos, p.nombre_partido, p.color
             ORDER BY total_votos DESC"""
    lista = ejecutar_consulta(sql, tuple(params))

    # Votos en blanco (con filtros)
    where_blanco = "WHERE v.id_eleccion = %s AND v.es_voto_blanco = 1"
    params_blanco = [id_eleccion]
    if id_caserio:
        where_blanco += " AND com.id_caserio = %s"
        params_blanco.append(id_caserio)
    if id_mesa:
        where_blanco += " AND com.id_mesa_sufragio = %s"
        params_blanco.append(id_mesa)
    sql_blanco = f"""SELECT COUNT(*) cantidad FROM votos v
                     INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
                     {where_blanco}"""
    blanco = ejecutar_consulta(sql_blanco, tuple(params_blanco), una_fila=True)
    total_blanco = blanco['cantidad'] if blanco else 0

    # Total de votos (con filtros)
    where_total = "WHERE v.id_eleccion = %s"
    params_total = [id_eleccion]
    if id_caserio:
        where_total += " AND com.id_caserio = %s"
        params_total.append(id_caserio)
    if id_mesa:
        where_total += " AND com.id_mesa_sufragio = %s"
        params_total.append(id_mesa)
    sql_total = f"""SELECT COUNT(*) cantidad FROM votos v
                   INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
                   {where_total}"""
    total_votos = ejecutar_consulta(sql_total, tuple(params_total), una_fila=True)
    total = total_votos['cantidad'] if total_votos else 0

    datos = []
    if lista:
        for r in lista:
            datos.append({
                'nombreCandidato': r['nombre_candidato'],
                'nombrePartido': r['nombre_partido'],
                'color': r.get('color', ''),
                'totalVotos': r['total_votos'],
                'porcentaje': round((r['total_votos'] / total * 100), 2) if total > 0 else 0
            })

    if total_blanco > 0 or not lista:
        datos.append({
            'nombreCandidato': 'VOTOS EN BLANCO',
            'nombrePartido': '',
            'color': '#6c757d',
            'totalVotos': total_blanco,
            'porcentaje': round((total_blanco / total * 100), 2) if total > 0 else 0
        })

    return respuesta(True, '', datos)


@resultados_bp.route('/por-caserio/<int:id_eleccion>', methods=['GET'])
def resultados_por_caserio(id_eleccion):
    """Resultados de participación por caserío."""
    sql = """SELECT ca.id_caserio, ca.nombre_caserio,
                    COUNT(DISTINCT v.id_comunero) votos_emitidos,
                    COUNT(DISTINCT com.id_comunero) total_habilitados
             FROM caserios ca
             LEFT JOIN comuneros com ON com.id_caserio = ca.id_caserio AND com.estado = 1
             LEFT JOIN votos v ON v.id_comunero = com.id_comunero AND v.id_eleccion = %s
             WHERE ca.activo = 1
             GROUP BY ca.id_caserio, ca.nombre_caserio
             ORDER BY ca.nombre_caserio"""
    lista = ejecutar_consulta(sql, (id_eleccion,))

    datos = []
    if lista:
        for r in lista:
            hab = r['total_habilitados'] or 0
            vot = r['votos_emitidos'] or 0
            datos.append({
                'idCaserio': r['id_caserio'],
                'nombreCaserio': r['nombre_caserio'],
                'votosEmitidos': vot,
                'totalHabilitados': hab,
                'porcentaje': round((vot / hab * 100), 2) if hab > 0 else 0
            })
    return respuesta(True, '', datos)


@resultados_bp.route('/por-mesa-caserio/<int:id_eleccion>/<int:id_caserio>', methods=['GET'])
def resultados_por_mesa_caserio(id_eleccion, id_caserio):
    """Desglose de resultados por mesa dentro de un caserío."""
    sql = """SELECT m.codigo_mesa, CONCAT(c.nombres, ' ', c.apellidos) nombre_candidato,
                    p.nombre_partido, p.color, COUNT(v.id_voto) total_votos
             FROM votos v
             INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
             INNER JOIN mesas_sufragio m ON com.id_mesa_sufragio = m.id_mesa_sufragio
             LEFT JOIN candidatos c ON v.id_candidato = c.id_candidato
             LEFT JOIN partidos p ON c.id_partido = p.id_partido
             WHERE v.id_eleccion = %s AND com.id_caserio = %s
             GROUP BY m.id_mesa_sufragio, m.codigo_mesa, c.id_candidato, c.nombres, c.apellidos, p.nombre_partido, p.color
             ORDER BY m.codigo_mesa, total_votos DESC"""
    lista = ejecutar_consulta(sql, (id_eleccion, id_caserio))

    datos = []
    if lista:
        for r in lista:
            datos.append({
                'codigoMesa': r['codigo_mesa'],
                'nombreCandidato': r['nombre_candidato'] if r.get('nombre_candidato') else 'Votos en Blanco',
                'nombrePartido': r.get('nombre_partido', ''),
                'color': r.get('color', '#6c757d'),
                'totalVotos': r['total_votos']
            })
    return respuesta(True, '', datos)


@resultados_bp.route('/filtro/<int:id_eleccion>', methods=['GET'])
def resultados_filtro(id_eleccion):
    """Endpoint dedicado: votos por candidato filtrados por ?idCaserio=X&idMesa=Y"""
    id_caserio = request.args.get('idCaserio', type=int)
    id_mesa = request.args.get('idMesa', type=int)

    where_candidatos = "AND v.es_voto_blanco = 0"
    params = [id_eleccion]
    if id_caserio:
        where_candidatos += " AND com.id_caserio = %s"
        params.append(id_caserio)
    if id_mesa:
        where_candidatos += " AND com.id_mesa_sufragio = %s"
        params.append(id_mesa)

    sql = f"""SELECT CONCAT(c.nombres, ' ', c.apellidos) nombre_candidato,
                    p.nombre_partido, p.color, COUNT(v.id_voto) total_votos
             FROM votos v
             INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
             INNER JOIN candidatos c ON v.id_candidato = c.id_candidato
             INNER JOIN partidos p ON c.id_partido = p.id_partido
             WHERE v.id_eleccion = %s {where_candidatos}
             GROUP BY c.id_candidato, c.nombres, c.apellidos, p.nombre_partido, p.color
             ORDER BY total_votos DESC"""
    lista = ejecutar_consulta(sql, tuple(params))

    where_blanco = "WHERE v.id_eleccion = %s AND v.es_voto_blanco = 1"
    params_blanco = [id_eleccion]
    if id_caserio:
        where_blanco += " AND com.id_caserio = %s"
        params_blanco.append(id_caserio)
    if id_mesa:
        where_blanco += " AND com.id_mesa_sufragio = %s"
        params_blanco.append(id_mesa)
    sql_blanco = f"""SELECT COUNT(*) cantidad FROM votos v
                     INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
                     {where_blanco}"""
    blanco = ejecutar_consulta(sql_blanco, tuple(params_blanco), una_fila=True)
    total_blanco = blanco['cantidad'] if blanco else 0

    where_total = "WHERE v.id_eleccion = %s"
    params_total = [id_eleccion]
    if id_caserio:
        where_total += " AND com.id_caserio = %s"
        params_total.append(id_caserio)
    if id_mesa:
        where_total += " AND com.id_mesa_sufragio = %s"
        params_total.append(id_mesa)
    sql_total = f"""SELECT COUNT(*) cantidad FROM votos v
                   INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
                   {where_total}"""
    total_votos = ejecutar_consulta(sql_total, tuple(params_total), una_fila=True)
    total = total_votos['cantidad'] if total_votos else 0

    datos = []
    if lista:
        for r in lista:
            datos.append({
                'nombreCandidato': r['nombre_candidato'],
                'nombrePartido': r['nombre_partido'],
                'color': r.get('color', ''),
                'totalVotos': r['total_votos'],
                'porcentaje': round((r['total_votos'] / total * 100), 2) if total > 0 else 0
            })

    if total_blanco > 0 or not lista:
        datos.append({
            'nombreCandidato': 'VOTOS EN BLANCO',
            'nombrePartido': '',
            'color': '#6c757d',
            'totalVotos': total_blanco,
            'porcentaje': round((total_blanco / total * 100), 2) if total > 0 else 0
        })

    return respuesta(True, '', datos)


@resultados_bp.route('/general-completo/<int:id_eleccion>', methods=['GET'])
def resultados_general_completo(id_eleccion):
    """Resultados completos: mesa por mesa, caserío por caserío."""
    # Por mesa y caserío
    sql = """SELECT m.codigo_mesa, ca.nombre_caserio,
                    COALESCE(CONCAT(c.nombres, ' ', c.apellidos), 'Votos en Blanco') nombre_candidato,
                    COALESCE(p.color, '#6c757d') color, COUNT(v.id_voto) total_votos
             FROM votos v
             INNER JOIN comuneros com ON v.id_comunero = com.id_comunero
             INNER JOIN mesas_sufragio m ON com.id_mesa_sufragio = m.id_mesa_sufragio
             INNER JOIN caserios ca ON com.id_caserio = ca.id_caserio
             LEFT JOIN candidatos c ON v.id_candidato = c.id_candidato
             LEFT JOIN partidos p ON c.id_partido = p.id_partido
             WHERE v.id_eleccion = %s
             GROUP BY m.id_mesa_sufragio, m.codigo_mesa, ca.nombre_caserio,
                      c.id_candidato, c.nombres, c.apellidos, p.color
             ORDER BY ca.nombre_caserio, m.codigo_mesa, total_votos DESC"""
    lista = ejecutar_consulta(sql, (id_eleccion,))

    datos = []
    if lista:
        for r in lista:
            datos.append({
                'codigoMesa': r['codigo_mesa'],
                'nombreCaserio': r['nombre_caserio'],
                'nombreCandidato': r['nombre_candidato'],
                'color': r.get('color', ''),
                'totalVotos': r['total_votos']
            })
    return respuesta(True, '', datos)


# ---------------------------------------------------------------------------
# 6.14 DASHBOARD  /api/dashboard
# ---------------------------------------------------------------------------
dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/api/dashboard')


@dashboard_bp.route('', methods=['GET'])
@token_requerido
def obtener_dashboard():
    """Obtiene indicadores KPI para el dashboard principal."""
    kpis = {}

    # Total comuneros
    row = ejecutar_consulta("SELECT COUNT(*) cantidad FROM comuneros", una_fila=True)
    kpis['totalComuneros'] = row['cantidad'] if row else 0

    # Comuneros activos
    row = ejecutar_consulta("SELECT COUNT(*) cantidad FROM comuneros WHERE estado = 1", una_fila=True)
    kpis['comunerosActivos'] = row['cantidad'] if row else 0

    # Total caseríos
    row = ejecutar_consulta("SELECT COUNT(*) cantidad FROM caserios WHERE activo = 1", una_fila=True)
    kpis['totalCaserios'] = row['cantidad'] if row else 0

    # Total mesas
    row = ejecutar_consulta("SELECT COUNT(*) cantidad FROM mesas_sufragio WHERE activo = 1", una_fila=True)
    kpis['totalMesas'] = row['cantidad'] if row else 0

    # Total locales
    row = ejecutar_consulta("SELECT COUNT(*) cantidad FROM locales_votacion WHERE activo = 1", una_fila=True)
    kpis['totalLocales'] = row['cantidad'] if row else 0

    # Elección activa
    eleccion = ejecutar_consulta("""SELECT id_eleccion, nombre_eleccion,
                                           fecha_inicio_inscripcion, fecha_cierre_inscripcion,
                                           hora_inicio_inscripcion, hora_fin_inscripcion,
                                           fecha_votacion, hora_inicio_votacion, hora_fin_votacion,
                                           estado FROM elecciones
                                    WHERE activa = 1 LIMIT 1""", una_fila=True)
    if eleccion:
        kpis['eleccionActiva'] = {
            'idEleccion': eleccion['id_eleccion'],
            'nombreEleccion': eleccion['nombre_eleccion'],
            'estado': _calcular_estado_auto(
                str(eleccion.get('fecha_inicio_inscripcion', '')) or None,
                eleccion.get('hora_inicio_inscripcion'),
                str(eleccion.get('fecha_cierre_inscripcion', '')) or None,
                eleccion.get('hora_fin_inscripcion'),
                str(eleccion.get('fecha_votacion', '')) or None,
                eleccion.get('hora_inicio_votacion'),
                eleccion.get('hora_fin_votacion'))
        }

        # Votos emitidos
        votos = ejecutar_consulta(
            "SELECT COUNT(*) cantidad FROM votos WHERE id_eleccion = %s",
            (eleccion['id_eleccion'],), una_fila=True)
        kpis['votosEmitidos'] = votos['cantidad'] if votos else 0

        # Porcentaje de participación
        if kpis['comunerosActivos'] > 0:
            kpis['porcentajeParticipacion'] = round(
                (kpis['votosEmitidos'] / kpis['comunerosActivos'] * 100), 2)
        else:
            kpis['porcentajeParticipacion'] = 0
    else:
        kpis['eleccionActiva'] = None
        kpis['votosEmitidos'] = 0
        kpis['porcentajeParticipacion'] = 0

    # Total usuarios
    row = ejecutar_consulta("SELECT COUNT(*) cantidad FROM usuarios", una_fila=True)
    kpis['totalUsuarios'] = row['cantidad'] if row else 0

    return respuesta(True, '', kpis)


@dashboard_bp.route('/participacion', methods=['GET'])
@token_requerido
def datos_participacion():
    """Datos de participación para gráficos del dashboard."""
    eleccion = ejecutar_consulta(
        "SELECT id_eleccion FROM elecciones WHERE activa = 1 LIMIT 1", una_fila=True)
    if not eleccion:
        return respuesta(True, '', {'porCaserio': []})

    sql = """SELECT ca.nombre_caserio,
                    COUNT(DISTINCT v.id_comunero) votos,
                    COUNT(DISTINCT com.id_comunero) habilitados
             FROM caserios ca
             LEFT JOIN comuneros com ON com.id_caserio = ca.id_caserio AND com.estado = 1
             LEFT JOIN votos v ON v.id_comunero = com.id_comunero AND v.id_eleccion = %s
             WHERE ca.activo = 1
             GROUP BY ca.id_caserio, ca.nombre_caserio
             ORDER BY ca.nombre_caserio"""
    lista = ejecutar_consulta(sql, (eleccion['id_eleccion'],))

    datos = []
    if lista:
        for r in lista:
            hab = r['habilitados'] or 0
            vot = r['votos'] or 0
            datos.append({
                'nombreCaserio': r['nombre_caserio'],
                'votos': vot,
                'habilitados': hab,
                'porcentaje': round((vot / hab * 100), 2) if hab > 0 else 0
            })

    return respuesta(True, '', {'porCaserio': datos})


# ---------------------------------------------------------------------------
# 6.15 AUDITORÍA  /api/auditoria
# ---------------------------------------------------------------------------
auditoria_bp = Blueprint('auditoria', __name__, url_prefix='/api/auditoria')


@auditoria_bp.route('', methods=['GET'])
@token_requerido
def listar_auditoria():
    """Lista registros de auditoría con paginación y búsqueda."""
    pagina, por_pagina, offset = obtener_paginacion()
    busqueda = request.args.get('busqueda', '').strip()

    sql_base = """FROM auditoria a LEFT JOIN usuarios u ON a.id_usuario = u.id_usuario"""
    params = []
    if busqueda:
        sql_base += """ WHERE a.modulo LIKE %s OR a.accion LIKE %s OR a.detalle LIKE %s
                        OR u.nombre_usuario LIKE %s"""
        like = f"%{busqueda}%"
        params = [like, like, like, like]

    total_row = ejecutar_consulta(f"SELECT COUNT(*) cantidad {sql_base}", params, una_fila=True)
    total = total_row['cantidad'] if total_row else 0

    sql_datos = f"""SELECT a.id_auditoria, a.id_usuario, u.nombre_usuario, a.modulo,
                           a.accion, a.detalle, a.ip_origen, a.fecha_evento
                    {sql_base}
                    ORDER BY a.fecha_evento DESC LIMIT %s OFFSET %s"""
    lista = ejecutar_consulta(sql_datos, params + [por_pagina, offset])

    datos = []
    if lista:
        for a in lista:
            datos.append({
                'idAuditoria': a['id_auditoria'],
                'idUsuario': a.get('id_usuario'),
                'nombreUsuario': a.get('nombre_usuario', 'Sistema'),
                'modulo': a['modulo'],
                'accion': a['accion'],
                'detalle': a.get('detalle', ''),
                'ipOrigen': a.get('ip_origen', ''),
                'fechaEvento': str(a['fecha_evento']) if a.get('fecha_evento') else ''
            })
    return respuesta_paginada(datos, total, pagina, por_pagina)


# =============================================================================
# 7. REGISTRO DE BLUEPRINTS
# =============================================================================
app.register_blueprint(autenticacion_bp)
app.register_blueprint(usuarios_bp)
app.register_blueprint(roles_bp)
app.register_blueprint(elecciones_bp)
app.register_blueprint(caserios_bp)
app.register_blueprint(locales_bp)
app.register_blueprint(mesas_bp)
app.register_blueprint(comuneros_bp)
app.register_blueprint(partidos_bp)
app.register_blueprint(candidatos_bp)
app.register_blueprint(miembros_bp)
app.register_blueprint(votacion_bp)
app.register_blueprint(resultados_bp)
app.register_blueprint(dashboard_bp)
app.register_blueprint(auditoria_bp)


# =============================================================================
# 8. RUTA RAÍZ
# =============================================================================
@app.route('/')
def raiz():
    """Endpoint raíz con información de la API."""
    return jsonify({
        'mensaje': 'API REST del Sistema de Votación Electrónica - CCSPM',
        'version': '1.0.0',
        'entorno': os.environ.get('ENTORNO', 'pythonanywhere'),
        'endpoints': {
            'autenticacion': '/api/autenticacion',
            'usuarios': '/api/usuarios',
            'roles': '/api/roles',
            'elecciones': '/api/elecciones',
            'caserios': '/api/caserios',
            'locales-votacion': '/api/locales-votacion',
            'mesas-sufragio': '/api/mesas-sufragio',
            'comuneros': '/api/comuneros',
            'partidos': '/api/partidos',
            'candidatos': '/api/candidatos',
            'miembros-mesa': '/api/miembros-mesa',
            'votacion': '/api/votacion',
            'resultados': '/api/resultados',
            'dashboard': '/api/dashboard',
            'auditoria': '/api/auditoria'
        }
    })


# =============================================================================
# (El estado de elecciones se calcula automáticamente al crear o actualizar
#  mediante _calcular_estado_auto(). El frontend JS recalcula en tiempo real
#  con calcularEstado(). No hay scheduler background.)




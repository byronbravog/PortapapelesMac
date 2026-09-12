# Portapapeles

Aplicacion de barra de menus para macOS que guarda un historial de texto copiado.

## Requisitos

- macOS 14 o posterior
- Swift 5.9 o posterior

## Ejecutar en desarrollo

```bash
swift run --build-path .build
```

## Compilar en release

```bash
swift build -c release --build-path .build
```

El ejecutable se genera en `.build/x86_64-apple-macosx/release/Portapapeles`.

## Funcionalidades

- Historial persistente de texto copiado.
- Busqueda en el historial.
- Acceso desde la barra de menus.
- Pegado del elemento seleccionado con Enter o doble clic.

La aplicacion requiere permisos de Accesibilidad en macOS para simular `Cmd+V` en otras aplicaciones.

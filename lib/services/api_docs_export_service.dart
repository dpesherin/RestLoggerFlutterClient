import 'dart:math' as math;
import 'dart:convert';

import '../models/api_documentation_project.dart';

class ApiDocsExportService {
  static String buildPostmanCollection(ApiDocumentationProject project) {
    final grouped = <String, List<ApiRequestDefinition>>{};
    for (final request in project.requests) {
      grouped.putIfAbsent(request.group, () => <ApiRequestDefinition>[]).add(
            request,
          );
    }

    final collection = <String, dynamic>{
      'info': <String, dynamic>{
        'name': project.name,
        '_postman_id': project.id,
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        'description': project.description,
      },
      'variable': <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'baseUrl',
          'value': project.baseUrl,
          'type': 'string',
        },
      ],
      'auth': _postmanAuth(project.authConfig),
      'item': grouped.entries
          .map(
            (entry) => <String, dynamic>{
              'name': entry.key,
              'item': entry.value.map(_postmanItem).toList(),
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(collection);
  }

  static String buildOpenApiDocument(ApiDocumentationProject project) {
    final paths = <String, dynamic>{};
    final componentSchemas = <String, dynamic>{};

    for (final request in project.requests) {
      final pathKey = request.path.trim().isEmpty ? '/' : request.path.trim();
      final methodKey = request.method.toLowerCase();

      final operation = <String, dynamic>{
        'summary': request.name,
        if (_openApiOperationDescription(request) != null)
          'description': _openApiOperationDescription(request),
        'tags': <String>[request.group],
        if (request.pathParams.isNotEmpty || request.queryParams.isNotEmpty)
          'parameters': <Map<String, dynamic>>[
            ...request.pathParams.map(
              (param) => _openApiParameter(param, location: 'path'),
            ),
            ...request.queryParams.map(
              (param) => _openApiParameter(param, location: 'query'),
            ),
          ],
        if (_hasRequestBody(request))
          'requestBody': <String, dynamic>{
            'required': request.bodyFields.any((field) => field.required),
            if (_openApiRequestBodyDescription(request) != null)
              'description': _openApiRequestBodyDescription(request),
            'content': <String, dynamic>{
              _openApiContentType(request): <String, dynamic>{
                'schema': _openApiRequestBodySchema(
                  request,
                  componentSchemas: componentSchemas,
                ),
                if (_openApiRequestExample(request) != null)
                  'example': _openApiRequestExample(request),
              },
            },
          },
        'responses': <String, dynamic>{
          for (final response in request.responses)
            '${response.statusCode}': <String, dynamic>{
              'description': response.description,
              'content': <String, dynamic>{
                'application/json': <String, dynamic>{
                  if (response.bodyExample.isNotEmpty)
                    'example': _tryDecodeJson(response.bodyExample),
                },
              },
            },
        },
        if (!request.useProjectAuth || project.authConfig.type != 'none')
          'security': <Map<String, dynamic>>[
            <String, dynamic>{
              _securitySchemeName(
                request.useProjectAuth
                    ? project.authConfig
                    : request.authConfig,
              ): <dynamic>[],
            },
          ],
      };

      final pathEntry = paths.putIfAbsent(pathKey, () => <String, dynamic>{})
          as Map<String, dynamic>;
      pathEntry[methodKey] = operation;
    }

    final activeSchemes = <String, dynamic>{};
    if (project.authConfig.type != 'none') {
      activeSchemes[_securitySchemeName(project.authConfig)] =
          _openApiSecurityScheme(project.authConfig);
    }
    for (final request in project.requests) {
      if (!request.useProjectAuth && request.authConfig.type != 'none') {
        activeSchemes[_securitySchemeName(request.authConfig)] =
            _openApiSecurityScheme(request.authConfig);
      }
    }

    final document = <String, dynamic>{
      'openapi': '3.0.3',
      'info': <String, dynamic>{
        'title': project.name,
        'version': '1.0.0',
        if (project.description.isNotEmpty) 'description': project.description,
      },
      'servers': <Map<String, dynamic>>[
        <String, dynamic>{'url': project.baseUrl},
      ],
      'paths': paths,
      if (activeSchemes.isNotEmpty || componentSchemas.isNotEmpty)
        'components': <String, dynamic>{
          if (activeSchemes.isNotEmpty) 'securitySchemes': activeSchemes,
          if (componentSchemas.isNotEmpty) 'schemas': componentSchemas,
        },
    };

    return const JsonEncoder.withIndent('  ').convert(document);
  }

  static Map<String, dynamic> _postmanItem(ApiRequestDefinition request) {
    final rawPath =
        request.path.startsWith('/') ? request.path : '/${request.path}';
    final pathSegments =
        rawPath.split('/').where((item) => item.isNotEmpty).toList();

    return <String, dynamic>{
      'name': request.name,
      'request': <String, dynamic>{
        'method': request.method,
        'description': _postmanRequestDescription(request),
        if (request.useProjectAuth == false &&
            request.authConfig.type != 'none')
          'auth': _postmanAuth(request.authConfig),
        'header': request.headers
            .where((entry) => entry.enabled)
            .map(
              (entry) => <String, dynamic>{
                'key': entry.key,
                'value': entry.value,
                'type': 'text',
              },
            )
            .toList(),
        'url': <String, dynamic>{
          'raw':
              '{{baseUrl}}$rawPath${_postmanQuerySuffix(request.queryParams)}',
          'host': <String>['{{baseUrl}}'],
          'path': pathSegments,
          if (request.queryParams.isNotEmpty)
            'query': request.queryParams
                .map(
                  (param) => <String, dynamic>{
                    'key': param.name,
                    'value': _postmanPrimitiveValue(_parameterExample(param)),
                    'description': param.description,
                    'disabled': !param.required,
                  },
                )
                .toList(),
          if (request.pathParams.isNotEmpty)
            'variable': request.pathParams
                .map(
                  (param) => <String, dynamic>{
                    'key': param.name,
                    'value': _postmanPrimitiveValue(_parameterExample(param)),
                    'description': param.description,
                  },
                )
                .toList(),
        },
        if (_postmanRequestBody(request) != null)
          'body': _postmanRequestBody(request),
      },
      'response': request.responses
          .map(
            (response) => <String, dynamic>{
              'name': response.description,
              'code': response.statusCode,
              'status': response.description,
              'body': response.bodyExample,
            },
          )
          .toList(),
    };
  }

  static String _postmanQuerySuffix(List<ApiParameterDefinition> params) {
    if (params.isEmpty) return '';
    final entries = params
        .map(
          (param) =>
              '${param.name}=${_postmanPrimitiveValue(_parameterExample(param))}',
        )
        .join('&');
    return '?$entries';
  }

  static Map<String, dynamic>? _postmanAuth(ApiAuthConfig config) {
    switch (config.type) {
      case 'bearer':
        return <String, dynamic>{
          'type': 'bearer',
          'bearer': <Map<String, dynamic>>[
            <String, dynamic>{
              'key': 'token',
              'value': config.token,
              'type': 'string'
            },
          ],
        };
      case 'basic':
        return <String, dynamic>{
          'type': 'basic',
          'basic': <Map<String, dynamic>>[
            <String, dynamic>{
              'key': 'username',
              'value': config.username,
              'type': 'string'
            },
            <String, dynamic>{
              'key': 'password',
              'value': config.password,
              'type': 'string'
            },
          ],
        };
      case 'apiKey':
        return <String, dynamic>{
          'type': 'apikey',
          'apikey': <Map<String, dynamic>>[
            <String, dynamic>{
              'key': 'key',
              'value': config.apiKeyName,
              'type': 'string'
            },
            <String, dynamic>{
              'key': 'value',
              'value': config.apiKey,
              'type': 'string'
            },
            <String, dynamic>{
              'key': 'in',
              'value': config.apiKeyLocation,
              'type': 'string'
            },
          ],
        };
      default:
        return null;
    }
  }

  static Map<String, dynamic> _openApiParameter(
    ApiParameterDefinition param, {
    required String location,
  }) {
    return <String, dynamic>{
      'name': param.name,
      'in': location,
      'required': location == 'path' ? true : param.required,
      if (_openApiParameterDescription(param) != null)
        'description': _openApiParameterDescription(param),
      'schema': _schemaFromParameter(param),
      if (_parameterExample(param) != null)
        'example': _castExample(_parameterExample(param)!, param.type),
    };
  }

  static Map<String, dynamic> _schemaFromParameter(
      ApiParameterDefinition param) {
    if (param.isArray) {
      return <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{
          ..._schemaType(param.arrayItemType),
          if (_parameterArrayItemDescription(param) != null)
            'description': _parameterArrayItemDescription(param),
          if (param.arrayItemExample.isNotEmpty)
            'example':
                _castExample(param.arrayItemExample, param.arrayItemType),
        },
      };
    }
    return <String, dynamic>{
      ..._schemaType(param.type),
      if (param.isDictionary && param.dictionaryEntries.isNotEmpty)
        'enum': param.dictionaryEntries
            .map((entry) => _castExample(entry.value, param.type))
            .toList(),
      if (_parameterExample(param) != null)
        'default': _castExample(_parameterExample(param)!, param.type),
    };
  }

  static Map<String, dynamic> _openApiRequestBodySchema(
      ApiRequestDefinition request,
      {required Map<String, dynamic> componentSchemas}) {
    if (request.bodyMode == 'none' || request.bodyFields.isEmpty) {
      return <String, dynamic>{'type': 'object'};
    }
    return _schemaFromBodyFields(
      request.bodyFields,
      componentSchemas: componentSchemas,
    );
  }

  static Map<String, dynamic> _schemaFromBodyFields(
    List<ApiBodyFieldDefinition> fields, {
    required Map<String, dynamic> componentSchemas,
  }) {
    return <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        for (final field in fields)
          field.name: _schemaFromBodyField(
            field,
            componentSchemas: componentSchemas,
            componentNameHint: _componentBaseName(
              field.name,
              fallback: 'Field',
            ),
          ),
      },
      'required': fields
          .where((field) => field.required)
          .map((field) => field.name)
          .toList(),
    };
  }

  static Map<String, dynamic> _schemaFromBodyField(
    ApiBodyFieldDefinition field, {
    required Map<String, dynamic> componentSchemas,
    required String componentNameHint,
  }) {
    if (field.isArray) {
      final itemsSchema = field.arrayItemType == 'object'
          ? _registerComponentSchema(
              componentSchemas,
              componentNameHint,
              _schemaFromBodyFields(
                field.children,
                componentSchemas: componentSchemas,
              ),
            )
          : <String, dynamic>{
              ..._schemaType(field.arrayItemType),
              if (field.arrayItemDescription.isNotEmpty)
                'description': field.arrayItemDescription,
              if (field.arrayItemExample.isNotEmpty)
                'example':
                    _castExample(field.arrayItemExample, field.arrayItemType),
            };

      return <String, dynamic>{
        'type': 'array',
        if (field.description.isNotEmpty) 'description': field.description,
        'items': itemsSchema,
      };
    }
    if (field.type == 'object') {
      final ref = _registerComponentSchema(
        componentSchemas,
        componentNameHint,
        _schemaFromBodyFields(
          field.children,
          componentSchemas: componentSchemas,
        ),
      );
      return <String, dynamic>{
        ...ref,
        if (field.description.isNotEmpty) 'description': field.description,
      };
    }
    return <String, dynamic>{
      ..._schemaType(field.type),
      if (_openApiBodyFieldDescription(field) != null)
        'description': _openApiBodyFieldDescription(field),
      if (field.isDictionary && field.dictionaryEntries.isNotEmpty)
        'enum': field.dictionaryEntries
            .map((entry) => _castExample(entry.value, field.type))
            .toList(),
      if (_bodyFieldExample(field) != null)
        'example': _castExample(_bodyFieldExample(field)!, field.type),
      if (_bodyFieldExample(field) != null)
        'default': _castExample(_bodyFieldExample(field)!, field.type),
    };
  }

  static Map<String, dynamic> _schemaType(String type) {
    switch (type) {
      case 'integer':
        return <String, dynamic>{'type': 'integer'};
      case 'number':
        return <String, dynamic>{'type': 'number'};
      case 'boolean':
        return <String, dynamic>{'type': 'boolean'};
      case 'object':
        return <String, dynamic>{'type': 'object'};
      case 'array':
        return <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{'type': 'string'}
        };
      default:
        return <String, dynamic>{'type': 'string'};
    }
  }

  static dynamic _castExample(String value, String type) {
    switch (type) {
      case 'integer':
        return int.tryParse(value) ?? value;
      case 'number':
        return num.tryParse(value) ?? value;
      case 'boolean':
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
        return value;
      case 'object':
      case 'array':
        return _tryDecodeJson(value);
      default:
        return value;
    }
  }

  static dynamic _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  static Map<String, dynamic> _requestExampleBody(
    ApiRequestDefinition request,
  ) {
    return <String, dynamic>{
      for (final field in request.bodyFields)
        field.name: _bodyFieldExampleValue(field),
    };
  }

  static String _securitySchemeName(ApiAuthConfig config) {
    switch (config.type) {
      case 'bearer':
        return 'bearerAuth';
      case 'basic':
        return 'basicAuth';
      case 'apiKey':
        return 'apiKeyAuth';
      default:
        return 'defaultAuth';
    }
  }

  static Map<String, dynamic> _openApiSecurityScheme(ApiAuthConfig config) {
    switch (config.type) {
      case 'bearer':
        return <String, dynamic>{
          'type': 'http',
          'scheme': config.scheme.toLowerCase(),
          'bearerFormat': 'JWT',
        };
      case 'basic':
        return <String, dynamic>{
          'type': 'http',
          'scheme': 'basic',
        };
      case 'apiKey':
        return <String, dynamic>{
          'type': 'apiKey',
          'name': config.apiKeyName,
          'in': config.apiKeyLocation,
        };
      default:
        return <String, dynamic>{'type': 'http', 'scheme': 'bearer'};
    }
  }

  static bool _hasRequestBody(ApiRequestDefinition request) {
    if (request.bodyMode == 'none') return false;
    return request.bodyFields.isNotEmpty || request.requestBody.isNotEmpty;
  }

  static String _openApiContentType(ApiRequestDefinition request) {
    switch (request.bodyMode) {
      case 'form-data':
        return 'multipart/form-data';
      case 'x-www-form-urlencoded':
        return 'application/x-www-form-urlencoded';
      case 'json':
      default:
        return 'application/json';
    }
  }

  static dynamic _openApiRequestExample(ApiRequestDefinition request) {
    if (request.bodyMode == 'json' && request.requestBody.isNotEmpty) {
      return _tryDecodeJson(request.requestBody);
    }
    if (request.bodyFields.isNotEmpty) {
      return _requestExampleBody(request);
    }
    if (request.requestBody.isNotEmpty) {
      return _tryDecodeJson(request.requestBody);
    }
    return null;
  }

  static Map<String, dynamic>? _postmanRequestBody(
    ApiRequestDefinition request,
  ) {
    if (!_hasRequestBody(request)) return null;

    switch (request.bodyMode) {
      case 'form-data':
        return <String, dynamic>{
          'mode': 'formdata',
          'formdata': request.bodyFields
              .map(
                (field) => <String, dynamic>{
                  'key': field.name,
                  'value': field.isArray
                      ? _postmanArrayValue(field.arrayItemExample)
                      : _postmanPrimitiveValue(_bodyFieldExample(field)),
                  'type': 'text',
                  if (field.description.isNotEmpty)
                    'description': field.description,
                  'disabled': !field.required,
                },
              )
              .toList(),
        };
      case 'x-www-form-urlencoded':
        return <String, dynamic>{
          'mode': 'urlencoded',
          'urlencoded': request.bodyFields
              .map(
                (field) => <String, dynamic>{
                  'key': field.name,
                  'value': field.isArray
                      ? _postmanArrayValue(field.arrayItemExample)
                      : _postmanPrimitiveValue(_bodyFieldExample(field)),
                  if (field.description.isNotEmpty)
                    'description': field.description,
                  'disabled': !field.required,
                },
              )
              .toList(),
        };
      case 'json':
      default:
        return <String, dynamic>{
          'mode': 'raw',
          'raw': request.requestBody.isNotEmpty
              ? request.requestBody
              : const JsonEncoder.withIndent('  ')
                  .convert(_requestExampleBody(request)),
          'options': <String, dynamic>{
            'raw': <String, dynamic>{'language': 'json'},
          },
        };
    }
  }

  static String _postmanArrayValue(String value) {
    if (value.isEmpty) return '';
    return value;
  }

  static String _postmanRequestDescription(ApiRequestDefinition request) {
    final overview = <String>[
      '- **Method:** ${_postmanMethodBadge(request.method)}',
      '- **Path:** `${request.path}`',
      if (request.group.trim().isNotEmpty)
        '- **Collection:** `${request.group}`',
    ].join('\n');

    final sections = <String>[
      '# ${request.name}',
      if (request.description.isNotEmpty) request.description,
      _postmanDivider(),
      '## Overview',
      _postmanInfoBlock(overview),
      '### Endpoint',
      _postmanCodeBlock(
        '${request.method} ${request.path}',
        language: 'http',
      ),
    ];

    final authSection = _authDocumentation(
      request.useProjectAuth ? null : request.authConfig,
      usesProjectAuth: request.useProjectAuth,
    );
    if (authSection != null) {
      sections.addAll(<String>[
        _postmanDivider(),
        '## Auth',
        _postmanInfoBlock(authSection),
      ]);
    }

    if (request.pathParams.isNotEmpty) {
      sections.addAll(<String>[
        _postmanDivider(),
        '## Path Params',
        ...request.pathParams.map(
          (param) => _postmanParameterDoc(
            param,
            requiredOverride: true,
          ),
        ),
      ]);
    }

    if (request.queryParams.isNotEmpty) {
      sections.addAll(<String>[
        _postmanDivider(),
        '## Query Params',
        ...request.queryParams.map(_postmanParameterDoc),
      ]);
    }

    if (request.headers.isNotEmpty) {
      sections.addAll(<String>[
        _postmanDivider(),
        '## Headers',
        ...request.headers.map(
          (header) => _postmanHeaderDoc(
            key: header.key,
            value: header.value,
            enabled: header.enabled,
          ),
        ),
      ]);
    }

    if (_hasRequestBody(request)) {
      final schemaDocs = _collectPostmanSchemas(request.bodyFields);
      sections.addAll(<String>[
        _postmanDivider(),
        '## Request Body',
        _postmanInfoBlock(
          '- **Mode:** `${request.bodyMode}`\n'
          '- **Content-Type:** `${_openApiContentType(request)}`',
        ),
      ]);
      if (request.bodyMode == 'json' && request.requestBody.isNotEmpty) {
        sections.add('### JSON Template');
        sections
            .add(_postmanCodeBlock(_prettyJsonForDocs(request.requestBody)));
      }
      if (request.bodyFields.isNotEmpty) {
        sections.add('### Fields');
        sections.addAll(
          request.bodyFields.map(
            (field) => _postmanBodyFieldDoc(
              field,
              schemaNamesByFieldId: schemaDocs.schemaNamesByFieldId,
            ),
          ),
        );
      }
      if (schemaDocs.schemas.isNotEmpty) {
        sections.add('### Schemas');
        sections.addAll(
          schemaDocs.schemas.map(
            (schema) => _postmanSchemaDoc(
              schema,
              schemaNamesByFieldId: schemaDocs.schemaNamesByFieldId,
            ),
          ),
        );
      }
    }

    if (request.responses.isNotEmpty) {
      sections.addAll(<String>[
        _postmanDivider(),
        '## Responses',
        ...request.responses.map(
          _postmanResponseDoc,
        ),
      ]);
    }

    return sections.join('\n\n');
  }

  static String? _openApiOperationDescription(ApiRequestDefinition request) {
    final parts = <String>[
      if (request.description.isNotEmpty) request.description,
      'Endpoint: `${request.method} ${request.path}`',
    ];

    final authSection = _authDocumentation(
      request.useProjectAuth ? null : request.authConfig,
      usesProjectAuth: request.useProjectAuth,
    );
    if (authSection != null) {
      parts.add('Auth: $authSection');
    }

    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  static String? _openApiRequestBodyDescription(ApiRequestDefinition request) {
    if (request.bodyFields.isEmpty) return null;
    return request.bodyFields
        .map(
          (field) => _postmanFieldDocLine(
            name: field.name,
            typeLabel: _fieldTypeLabel(
              isArray: field.isArray,
              type: field.type,
              arrayItemType: field.arrayItemType,
            ),
            required: field.required,
            description: _openApiBodyFieldDescription(field),
          ),
        )
        .join('\n');
  }

  static String? _openApiParameterDescription(ApiParameterDefinition param) {
    return _composeDescription(
      baseDescription: param.description,
      required: param.required,
      typeLabel: _fieldTypeLabel(
        isArray: param.isArray,
        type: param.type,
        arrayItemType: param.arrayItemType,
      ),
      dictionaryEntries:
          param.isDictionary ? param.dictionaryEntries : const [],
      arrayItemDescription:
          param.isArray ? _parameterArrayItemDescription(param) : null,
    );
  }

  static String? _openApiBodyFieldDescription(ApiBodyFieldDefinition field) {
    return _composeDescription(
      baseDescription: field.description,
      required: field.required,
      typeLabel: _fieldTypeLabel(
        isArray: field.isArray,
        type: field.type,
        arrayItemType: field.arrayItemType,
      ),
      dictionaryEntries:
          field.isDictionary ? field.dictionaryEntries : const [],
      arrayItemDescription:
          field.isArray ? _bodyArrayItemDescription(field) : null,
      nestedFields: field.children,
    );
  }

  static String? _composeDescription({
    required String baseDescription,
    required bool required,
    required String typeLabel,
    required List<ApiDictionaryEntry> dictionaryEntries,
    String? arrayItemDescription,
    List<ApiBodyFieldDefinition> nestedFields =
        const <ApiBodyFieldDefinition>[],
  }) {
    final parts = <String>[
      if (baseDescription.trim().isNotEmpty) baseDescription.trim(),
      'Type: $typeLabel',
      'Required: ${required ? 'yes' : 'no'}',
      if (arrayItemDescription != null &&
          arrayItemDescription.trim().isNotEmpty)
        'Array item: ${arrayItemDescription.trim()}',
      if (dictionaryEntries.isNotEmpty) ...[
        'Allowed values:',
        for (final entry in dictionaryEntries)
          '- ${entry.value}: ${entry.description}',
      ],
      if (nestedFields.isNotEmpty) ...[
        'Nested fields:',
        for (final field in nestedFields)
          '- ${field.name} (${_fieldTypeLabel(isArray: field.isArray, type: field.type, arrayItemType: field.arrayItemType)})'
              '${field.required ? ', required' : ''}'
              '${field.description.isNotEmpty ? ': ${field.description}' : ''}',
      ],
    ];
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }

  static String _postmanFieldDocLine({
    required String name,
    required String typeLabel,
    required bool required,
    required String? description,
  }) {
    final buffer = StringBuffer('- `$name` (`$typeLabel`');
    if (required) {
      buffer.write(', required');
    }
    buffer.write(')');
    if (description != null && description.trim().isNotEmpty) {
      buffer.write(': ${description.trim().replaceAll('\n', ' ')}');
    }
    return buffer.toString();
  }

  static String _postmanParameterDoc(
    ApiParameterDefinition param, {
    bool? requiredOverride,
    int depth = 0,
  }) {
    final lines = <String>[
      _postmanFieldTitle(
        name: param.name,
        depth: depth,
      ),
      _postmanInfoBlock(
        '- **Type:** `${_fieldTypeLabel(isArray: param.isArray, type: param.type, arrayItemType: param.arrayItemType)}`\n'
        '- **Required:** `${(requiredOverride ?? param.required) ? 'yes' : 'no'}`',
      ),
    ];

    if (param.description.isNotEmpty) {
      lines.add('**Description**');
      lines.add(param.description);
    }
    if (param.isDictionary && param.dictionaryEntries.isNotEmpty) {
      lines.add('');
      lines.add('**Allowed values**');
      for (final entry in param.dictionaryEntries) {
        lines.add(
          '- `${entry.value}`${entry.description.isNotEmpty ? ' - ${entry.description}' : ''}',
        );
      }
    }
    if (param.isArray) {
      if (param.arrayItemDescription.isNotEmpty) {
        lines
            .add('- **Array item description:** ${param.arrayItemDescription}');
      }
      if (param.arrayItemExample.isNotEmpty) {
        lines.add('- **Array item example:** `${param.arrayItemExample}`');
      }
    } else if (_parameterExample(param) != null) {
      lines.add('- **Example:** `${_parameterExample(param)}`');
    }

    return lines.join('\n');
  }

  static String _postmanBodyFieldDoc(
    ApiBodyFieldDefinition field, {
    int depth = 0,
    Map<String, String> schemaNamesByFieldId = const <String, String>{},
  }) {
    final schemaLabel =
        _postmanSchemaLabelForField(field, schemaNamesByFieldId);
    final lines = <String>[
      _postmanFieldTitle(
        name: field.name,
        depth: depth,
      ),
      _postmanInfoBlock(
        '- **Type:** `${schemaLabel ?? _fieldTypeLabel(isArray: field.isArray, type: field.type, arrayItemType: field.arrayItemType)}`\n'
        '- **Required:** `${field.required ? 'yes' : 'no'}`',
      ),
    ];

    if (field.description.isNotEmpty) {
      lines.add('**Description**');
      lines.add(field.description);
    }
    if (field.isDictionary && field.dictionaryEntries.isNotEmpty) {
      lines.add('');
      lines.add('**Allowed values**');
      for (final entry in field.dictionaryEntries) {
        lines.add(
          '- `${entry.value}`${entry.description.isNotEmpty ? ' - ${entry.description}' : ''}',
        );
      }
    }
    if (field.isArray) {
      if (field.arrayItemDescription.isNotEmpty) {
        lines
            .add('- **Array item description:** ${field.arrayItemDescription}');
      }
      if (field.arrayItemExample.isNotEmpty) {
        lines.add('- **Array item example:** `${field.arrayItemExample}`');
      }
      if (field.arrayItemType == 'object' && field.children.isNotEmpty) {
        final schemaName = schemaNamesByFieldId[field.id];
        if (schemaName != null) {
          lines.add('- **Array item schema:** `$schemaName`');
        } else {
          lines.add('');
          lines.add('**Array item fields**');
          for (final child in field.children) {
            lines.add(
              _postmanBodyFieldDoc(
                child,
                depth: depth + 1,
                schemaNamesByFieldId: schemaNamesByFieldId,
              ),
            );
          }
        }
      }
    } else if (field.type == 'object' && field.children.isNotEmpty) {
      final schemaName = schemaNamesByFieldId[field.id];
      if (schemaName != null) {
        lines.add('- **Schema:** `$schemaName`');
      } else {
        lines.add('');
        lines.add('**Nested fields**');
        for (final child in field.children) {
          lines.add(
            _postmanBodyFieldDoc(
              child,
              depth: depth + 1,
              schemaNamesByFieldId: schemaNamesByFieldId,
            ),
          );
        }
      }
    } else if (_bodyFieldExample(field) != null) {
      final exampleValue = _bodyFieldExample(field)!;
      final codeBlock = _postmanCodeBlockIfJson(exampleValue);
      if (codeBlock != null) {
        lines.add('');
        lines.add('**Example**');
        lines.add(codeBlock);
      } else {
        lines.add('- **Example:** `$exampleValue`');
      }
    }

    return lines.join('\n');
  }

  static _PostmanSchemaCollection _collectPostmanSchemas(
    List<ApiBodyFieldDefinition> fields,
  ) {
    final schemas = <_PostmanSchemaDoc>[];
    final schemaNamesByFieldId = <String, String>{};
    final usedSchemaNames = <String>{};

    void collect(List<ApiBodyFieldDefinition> nodes) {
      for (final field in nodes) {
        final isObjectSchema = (!field.isArray && field.type == 'object') ||
            (field.isArray && field.arrayItemType == 'object');
        if (isObjectSchema && field.children.isNotEmpty) {
          final schemaName = _ensureUniqueSchemaDocName(
            usedSchemaNames,
            _componentBaseName(field.name, fallback: 'Field'),
          );
          usedSchemaNames.add(schemaName);
          schemaNamesByFieldId[field.id] = schemaName;
          schemas.add(
            _PostmanSchemaDoc(
              name: schemaName,
              description: field.description,
              fields: field.children,
            ),
          );
          collect(field.children);
        }
      }
    }

    collect(fields);
    return _PostmanSchemaCollection(
      schemas: schemas,
      schemaNamesByFieldId: schemaNamesByFieldId,
    );
  }

  static String _ensureUniqueSchemaDocName(
    Set<String> usedSchemaNames,
    String baseName,
  ) {
    if (!usedSchemaNames.contains(baseName)) {
      return baseName;
    }

    var index = 2;
    while (usedSchemaNames.contains('$baseName$index')) {
      index++;
    }
    return '$baseName$index';
  }

  static String _postmanSchemaDoc(
    _PostmanSchemaDoc schema, {
    required Map<String, String> schemaNamesByFieldId,
  }) {
    final lines = <String>[
      '#### `${schema.name}`',
      _postmanInfoBlock('- **Type:** `object`'),
    ];
    if (schema.description.trim().isNotEmpty) {
      lines.add('**Description**');
      lines.add(schema.description.trim());
    }
    lines.add('');
    lines.add('**Fields**');
    for (final field in schema.fields) {
      lines.add(
        _postmanBodyFieldDoc(
          field,
          schemaNamesByFieldId: schemaNamesByFieldId,
        ),
      );
    }
    return lines.join('\n');
  }

  static String? _postmanSchemaLabelForField(
    ApiBodyFieldDefinition field,
    Map<String, String> schemaNamesByFieldId,
  ) {
    final schemaName = schemaNamesByFieldId[field.id];
    if (schemaName == null) {
      return null;
    }
    if (field.isArray && field.arrayItemType == 'object') {
      return 'array of $schemaName';
    }
    if (!field.isArray && field.type == 'object') {
      return schemaName;
    }
    return null;
  }

  static String _postmanHeaderDoc({
    required String key,
    required String value,
    required bool enabled,
  }) {
    final lines = <String>[
      '### `${key.isEmpty ? 'header' : key}`',
      _postmanInfoBlock(
        '- **Value:** `${value.isEmpty ? '-' : value}`\n'
        '- **Status:** `${enabled ? 'enabled' : 'disabled'}`',
      ),
    ];
    return lines.join('\n');
  }

  static String _postmanResponseDoc(ApiResponseDefinition response) {
    final lines = <String>[
      '### `${response.statusCode}` ${response.description}',
    ];
    if (response.bodyExample.isNotEmpty) {
      lines.add('');
      lines.add('**Example body**');
      lines.add(_postmanCodeBlock(_prettyJsonForDocs(response.bodyExample)));
    }
    return lines.join('\n');
  }

  static String _postmanFieldTitle({
    required String name,
    required int depth,
  }) {
    final headingLevel = math.min(4 + depth, 6);
    final headingPrefix = '#' * headingLevel;
    return '$headingPrefix `${name.isEmpty ? 'field' : name}`';
  }

  static String _postmanInfoBlock(String value) {
    return value
        .split('\n')
        .map((line) => '> ${line.trim().isEmpty ? ' ' : line}')
        .join('\n');
  }

  static String _postmanDivider() => '---';

  static String _postmanMethodBadge(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return '`🟢 GET`';
      case 'POST':
        return '`🟠 POST`';
      case 'PUT':
        return '`🟡 PUT`';
      case 'PATCH':
        return '`🟣 PATCH`';
      case 'DELETE':
        return '`🔴 DELETE`';
      default:
        return '`${method.toUpperCase()}`';
    }
  }

  static String _postmanCodeBlock(String value, {String language = 'json'}) {
    return '```$language\n$value\n```';
  }

  static String? _postmanCodeBlockIfJson(String value) {
    final prettyJson = _prettyJsonForDocs(value);
    if (prettyJson == value && !_looksLikeJson(value)) {
      return null;
    }
    return _postmanCodeBlock(prettyJson);
  }

  static String _prettyJsonForDocs(String value) {
    final decoded = _tryDecodeJson(value);
    if (decoded is Map || decoded is List) {
      return const JsonEncoder.withIndent('  ').convert(decoded);
    }
    return value;
  }

  static bool _looksLikeJson(String value) {
    final trimmed = value.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  static String _fieldTypeLabel({
    required bool isArray,
    required String type,
    required String arrayItemType,
  }) {
    if (isArray) {
      return 'array of $arrayItemType';
    }
    return type;
  }

  static String? _parameterArrayItemDescription(ApiParameterDefinition param) {
    final parts = <String>[
      if (param.arrayItemDescription.isNotEmpty) param.arrayItemDescription,
      if (param.arrayItemExample.isNotEmpty)
        'Example: ${param.arrayItemExample}',
    ];
    if (parts.isEmpty) return null;
    return parts.join('. ');
  }

  static String? _bodyArrayItemDescription(ApiBodyFieldDefinition field) {
    final parts = <String>[
      if (field.arrayItemDescription.isNotEmpty) field.arrayItemDescription,
      if (field.arrayItemExample.isNotEmpty)
        'Example: ${field.arrayItemExample}',
    ];
    if (parts.isEmpty) return null;
    return parts.join('. ');
  }

  static String? _authDocumentation(
    ApiAuthConfig? config, {
    required bool usesProjectAuth,
  }) {
    if (usesProjectAuth) {
      return 'Uses project auth configuration.';
    }
    if (config == null || config.type == 'none') {
      return null;
    }
    switch (config.type) {
      case 'bearer':
        return 'Bearer token in header `${config.headerName}` with scheme `${config.scheme}`.';
      case 'basic':
        return 'Basic auth with username and password.';
      case 'apiKey':
        return 'API key `${config.apiKeyName}` in `${config.apiKeyLocation}`.';
      default:
        return config.type;
    }
  }

  static Map<String, dynamic> _registerComponentSchema(
    Map<String, dynamic> componentSchemas,
    String componentName,
    Map<String, dynamic> schema,
  ) {
    final uniqueName =
        _ensureUniqueComponentName(componentSchemas, componentName);
    componentSchemas.putIfAbsent(uniqueName, () => schema);
    return <String, dynamic>{r'$ref': '#/components/schemas/$uniqueName'};
  }

  static String _ensureUniqueComponentName(
    Map<String, dynamic> componentSchemas,
    String baseName,
  ) {
    if (!componentSchemas.containsKey(baseName)) {
      return baseName;
    }

    var index = 2;
    while (componentSchemas.containsKey('$baseName$index')) {
      index++;
    }
    return '$baseName$index';
  }

  static String _componentBaseName(
    String source, {
    required String fallback,
  }) {
    final normalized = source.replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ').trim();
    if (normalized.isEmpty) return fallback;

    final pascal = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();

    return pascal.isEmpty ? fallback : '${pascal}Object';
  }

  static dynamic _bodyFieldExampleValue(ApiBodyFieldDefinition field) {
    if (field.isArray) {
      if (field.arrayItemType == 'object') {
        return <dynamic>[
          <String, dynamic>{
            for (final child in field.children)
              child.name: _bodyFieldExampleValue(child),
          },
        ];
      }
      return <dynamic>[
        if (field.arrayItemExample.isNotEmpty)
          _castExample(field.arrayItemExample, field.arrayItemType),
      ];
    }

    if (field.type == 'object') {
      return <String, dynamic>{
        for (final child in field.children)
          child.name: _bodyFieldExampleValue(child),
      };
    }

    return _castExample(_bodyFieldExample(field) ?? '', field.type);
  }

  static String? _parameterExample(ApiParameterDefinition param) {
    if (param.isDictionary && param.dictionaryEntries.isNotEmpty) {
      return param.dictionaryEntries.first.value;
    }
    if (param.example.isNotEmpty) {
      return param.example;
    }
    return null;
  }

  static String? _bodyFieldExample(ApiBodyFieldDefinition field) {
    if (field.isDictionary && field.dictionaryEntries.isNotEmpty) {
      return field.dictionaryEntries.first.value;
    }
    if (field.example.isNotEmpty) {
      return field.example;
    }
    return null;
  }

  static String _postmanPrimitiveValue(String? value) {
    if (value == null) return '';
    return value;
  }
}

class _PostmanSchemaCollection {
  final List<_PostmanSchemaDoc> schemas;
  final Map<String, String> schemaNamesByFieldId;

  const _PostmanSchemaCollection({
    required this.schemas,
    required this.schemaNamesByFieldId,
  });
}

class _PostmanSchemaDoc {
  final String name;
  final String description;
  final List<ApiBodyFieldDefinition> fields;

  const _PostmanSchemaDoc({
    required this.name,
    required this.description,
    required this.fields,
  });
}

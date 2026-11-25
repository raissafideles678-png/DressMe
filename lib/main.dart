import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void main() {
  runApp(const DressMeApp());
}

// ============================================================================
// TEMA & APP
// ============================================================================

class DressMeApp extends StatelessWidget {
  const DressMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const tinta = Color(0xFF151517);
    const cinza = Color(0xFF6D6D73);
    const fundo = Color(0xFFFAF9F7);
    const borda = Color(0xFFE9E6E0);

    return MaterialApp(
      title: 'Dress Me',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: fundo,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A1A1D),
          onPrimary: Colors.white,
          secondary: Color(0xFFF3F0EB),
          onSecondary: tinta,
          surface: Colors.white,
          onSurface: tinta,
          outline: borda,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: fundo,
          foregroundColor: tinta,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        dividerTheme: const DividerThemeData(color: borda, thickness: 1),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: tinta,
          ),
          titleMedium: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: tinta,
          ),
          bodyMedium: TextStyle(fontSize: 13.5, color: tinta),
          bodySmall: TextStyle(fontSize: 11.5, color: cinza),
        ),
      ),
      home: const DressMeShell(),
    );
  }
}

class _ConteudoCentralizado extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const _ConteudoCentralizado({
    required this.child,
    this.maxWidth = 700,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ============================================================================
// SELETOR NATIVO DE FOTO DO DISPOSITIVO
// ============================================================================

class SeletorImagemNativo {
  static Future<Uint8List?> escolherImagemDoDispositivo() async {
    if (!kIsWeb) return null;

    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(files.first);
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is ByteBuffer && !completer.isCompleted) {
          completer.complete(result.asUint8List());
        } else if (result is Uint8List && !completer.isCompleted) {
          completer.complete(result);
        } else if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
    });

    input.click();
    return completer.future;
  }
}

// ============================================================================
// WIDGET DE FOTO REAL DA PEÇA (MEMÓRIA, URL OU ASSET LOCAL)
// ============================================================================

class FotoPecaWidget extends StatelessWidget {
  final PecaRoupa peca;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool modoColagem;

  const FotoPecaWidget({
    super.key,
    required this.peca,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.modoColagem = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imagem;

    if (peca.fotoBytes != null) {
      imagem = Image.memory(
        peca.fotoBytes!,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _tentarUrlOuAsset(),
      );
    } else {
      imagem = _tentarUrlOuAsset();
    }

    if (modoColagem) {
      imagem = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.multiply,
        ),
        child: imagem,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imagem,
    );
  }

  Widget _tentarUrlOuAsset() {
    if (peca.fotoUrl != null && peca.fotoUrl!.trim().isNotEmpty) {
      return Image.network(
        peca.fotoUrl!.trim(),
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _tentarAsset(),
      );
    }
    return _tentarAsset();
  }

  Widget _tentarAsset() {
    if (peca.assetPath != null && peca.assetPath!.isNotEmpty) {
      return Image.asset(
        peca.assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackVisual(),
      );
    }
    return _fallbackVisual();
  }

  Widget _fallbackVisual() {
    return Container(
      width: width,
      height: height,
      color: peca.cor.withOpacity(0.14),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            peca.categoria.icon,
            size: 28,
            color: const Color(0xFF1A1A1D),
          ),
          const SizedBox(height: 6),
          Text(
            peca.nome,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF151517),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COLAGEM ESTILO "CREATE OUTFIT / LOOKS"
// ============================================================================

class ColagemLookWidget extends StatelessWidget {
  final Look look;
  final double height;

  const ColagemLookWidget({
    super.key,
    required this.look,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final cima = look.pecas
        .where((p) => p.categoria == CategoriaPeca.parteDeCima)
        .toList();
    final baixo = look.pecas
        .where((p) => p.categoria == CategoriaPeca.parteDeBaixo)
        .toList();
    final calcado = look.pecas
        .where((p) => p.categoria == CategoriaPeca.calcados)
        .toList();
    final acessorios = look.pecas
        .where((p) => p.categoria == CategoriaPeca.acessorios)
        .toList();

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (baixo.isNotEmpty)
            Align(
              alignment: const Alignment(0.18, 0.58),
              child: SizedBox(
                width: height * 0.44,
                height: height * 0.48,
                child: FotoPecaWidget(peca: baixo.first, modoColagem: true),
              ),
            ),
          if (cima.isNotEmpty)
            Align(
              alignment: const Alignment(-0.12, -0.72),
              child: SizedBox(
                width: height * 0.48,
                height: height * 0.44,
                child: FotoPecaWidget(peca: cima.first, modoColagem: true),
              ),
            ),
          if (acessorios.isNotEmpty)
            Align(
              alignment: const Alignment(-0.78, 0.35),
              child: SizedBox(
                width: height * 0.34,
                height: height * 0.34,
                child:
                    FotoPecaWidget(peca: acessorios.first, modoColagem: true),
              ),
            ),
          if (acessorios.length > 1)
            Align(
              alignment: const Alignment(0.76, -0.78),
              child: SizedBox(
                width: height * 0.30,
                height: height * 0.24,
                child: FotoPecaWidget(peca: acessorios[1], modoColagem: true),
              ),
            ),
          if (calcado.isNotEmpty)
            Align(
              alignment: const Alignment(0.68, 0.78),
              child: SizedBox(
                width: height * 0.36,
                height: height * 0.28,
                child: FotoPecaWidget(peca: calcado.first, modoColagem: true),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// MODELOS & REGRAS DE IA
// ============================================================================

enum CategoriaPeca {
  parteDeCima('Parte de Cima', Icons.checkroom_outlined),
  parteDeBaixo('Parte de Baixo', Icons.straighten_outlined),
  calcados('Calçados', Icons.hiking_outlined),
  acessorios('Acessórios', Icons.watch_outlined);

  final String label;
  final IconData icon;
  const CategoriaPeca(this.label, this.icon);
}

enum EstiloPeca {
  romantico('Romântico', Color(0xFFF8E7EC), Color(0xFF7B3548)),
  casual('Casual', Color(0xFFEDEAE3), Color(0xFF3E3A34)),
  streetwear('It Girl', Color(0xFFE6E8ED), Color(0xFF232730)),
  minimalista('Minimalista', Color(0xFFF1F1EE), Color(0xFF2D2D2B)),
  classico('Clássico', Color(0xFFEAE4DA), Color(0xFF4A3E2E)),
  esportivo('Esportivo', Color(0xFFE3ECE8), Color(0xFF244D3D));

  final String label;
  final Color fundoChip;
  final Color textoChip;
  const EstiloPeca(this.label, this.fundoChip, this.textoChip);
}

enum TipoCorpo {
  ampulheta(
    'Ampulheta',
    'Ombros/busto e quadril proporcionais com cintura definida. Valoriza blazers estruturados e saias retas.',
  ),
  pera(
    'Pêra',
    'Quadril maior que parte superior. Destaque o colo/ombros e use cortes retos ou fluidos embaixo.',
  ),
  trianguloInvertido(
    'Triângulo Invertido',
    'Parte superior mais ampla. Equilibre com saias evasê, bubble ou plissadas.',
  ),
  retangular(
    'Retangular',
    'Medidas próximas entre si. Crie volume e contorno com blazers, sobreposições e acessórios.',
  ),
  oval(
    'Oval',
    'Centro mais evidenciado. Alongue com linhas verticais e terceiras peças abertas.',
  );

  final String label;
  final String dica;
  const TipoCorpo(this.label, this.dica);
}

enum CartelaCor {
  primaveraClara(
    'Primavera Clara',
    'Tons claros e quentes: off-white, creme, verde claro, areia e pêssego.',
    [Color(0xFFFAF7F2), Color(0xFFC5D8B9), Color(0xFFD8C7AE), Color(0xFFA8D5BA)],
  ),
  outonoQuente(
    'Outono Quente',
    'Tons terrosos e quentes: cinza chumbo, tartaruga, marrom, vinho e caramelo.',
    [Color(0xFF5D6065), Color(0xFF7B5733), Color(0xFF6B2332), Color(0xFF8B5A2B)],
  ),
  invernoFrio(
    'Inverno Frio',
    'Tons frios e marcantes: preto, branco puro, cinza e marinho.',
    [Color(0xFF151517), Color(0xFFFFFFFF), Color(0xFF6D7075), Color(0xFF1D2D50)],
  ),
  veraoSuave(
    'Verão Suave',
    'Tons frios e suaves: cinza claro, azul denim claro, rosê e lavanda.',
    [Color(0xFFD8DCE0), Color(0xFF8AA8C7), Color(0xFFD6A8B4), Color(0xFFB8B5D1)],
  );

  final String label;
  final String resumo;
  final List<Color> cores;
  const CartelaCor(this.label, this.resumo, this.cores);
}

class MedidasCorporais {
  final double ombros;
  final double busto;
  final double cintura;
  final double quadril;

  const MedidasCorporais({
    this.ombros = 94,
    this.busto = 90,
    this.cintura = 68,
    this.quadril = 95,
  });

  TipoCorpo classificar() {
    final superior = max(ombros, busto);
    if (cintura >= superior * 0.94 && cintura >= quadril * 0.92) {
      return TipoCorpo.oval;
    }
    if ((quadril - superior) >= 6) return TipoCorpo.pera;
    if ((superior - quadril) >= 6) return TipoCorpo.trianguloInvertido;
    if ((superior - quadril).abs() <= 5.5 &&
        (superior - cintura) >= 16 &&
        (quadril - cintura) >= 18) {
      return TipoCorpo.ampulheta;
    }
    return TipoCorpo.retangular;
  }
}

class PerfilColoracao {
  final String subtom;
  final String contraste;

  const PerfilColoracao({
    this.subtom = 'Quente',
    this.contraste = 'Alto',
  });

  CartelaCor classificar() {
    if (subtom == 'Quente') {
      return contraste == 'Alto'
          ? CartelaCor.outonoQuente
          : CartelaCor.primaveraClara;
    }
    if (subtom == 'Frio') {
      return contraste == 'Alto'
          ? CartelaCor.invernoFrio
          : CartelaCor.veraoSuave;
    }
    return contraste == 'Alto'
        ? CartelaCor.invernoFrio
        : CartelaCor.primaveraClara;
  }
}

class PecaRoupa {
  final String id;
  final String nome;
  final String descricao;
  final CategoriaPeca categoria;
  final EstiloPeca estilo;
  final Color cor;
  final String ocasiao;
  final double preco;
  int vezesUsada;
  final String origem;
  final bool isWishlist;
  final String? assetPath;
  final String? fotoUrl;
  final Uint8List? fotoBytes;

  PecaRoupa({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.estilo,
    required this.cor,
    required this.ocasiao,
    required this.preco,
    this.vezesUsada = 0,
    this.origem = 'Guarda-Roupa',
    this.isWishlist = false,
    this.assetPath,
    this.fotoUrl,
    this.fotoBytes,
  });

  double get custoPorUso => vezesUsada <= 0 ? preco : preco / vezesUsada;
}

class Look {
  final String id;
  final String nome;
  final EstiloPeca estilo;
  final List<PecaRoupa> pecas;
  final String notaIA;

  Look({
    required this.id,
    required this.nome,
    required this.estilo,
    required this.pecas,
    this.notaIA = '',
  });
}

class EventoCalendario {
  final String id;
  final DateTime data;
  final String plano;
  final String clima;
  Look? look;
  bool usado;

  EventoCalendario({
    required this.id,
    required this.data,
    required this.plano,
    required this.clima,
    this.look,
    this.usado = false,
  });
}

// ============================================================================
// SHELL PRINCIPAL
// ============================================================================

class DressMeShell extends StatefulWidget {
  const DressMeShell({super.key});

  @override
  State<DressMeShell> createState() => _DressMeShellState();
}

class _DressMeShellState extends State<DressMeShell> {
  int _aba = 0;
  MedidasCorporais _medidas = const MedidasCorporais();
  PerfilColoracao _perfilCor = const PerfilColoracao();
  late TipoCorpo _tipoCorpo;
  late CartelaCor _cartelaCor;
  Look? _lookSelecionado;

  final List<PecaRoupa> _pecas = [
    PecaRoupa(
      id: '1',
      nome: 'Peça Seleção #1',
      descricao:
          'Peça escolhida da sua seleção para compor looks versáteis com caimento marcante.',
      categoria: CategoriaPeca.parteDeCima,
      estilo: EstiloPeca.classico,
      cor: const Color(0xFF5D6065),
      ocasiao: 'Dia a dia',
      preco: 219.90,
      vezesUsada: 10,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSGqwcgnaydf0M2-Q134J-lyopvgfiduHfhmAHht-DZPQ&s=10',
    ),
    PecaRoupa(
      id: '2',
      nome: 'Peça Seleção #2',
      descricao:
          'Segunda peça da sua seleção, perfeita para combinar com sobreposições ou itens básicos.',
      categoria: CategoriaPeca.parteDeCima,
      estilo: EstiloPeca.streetwear,
      cor: const Color(0xFF171719),
      ocasiao: 'Passeio',
      preco: 159.90,
      vezesUsada: 12,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSB9eykEOytMyUpeUFARVsr-ofaVxAOFLYbLnWgH8kiew&s=10',
    ),
    PecaRoupa(
      id: '3',
      nome: 'Peça Seleção #3',
      descricao:
          'Terceira peça da sua seleção, pensada para equilibrar proporções no look.',
      categoria: CategoriaPeca.parteDeBaixo,
      estilo: EstiloPeca.casual,
      cor: const Color(0xFF6E7176),
      ocasiao: 'Dia a dia',
      preco: 169.90,
      vezesUsada: 8,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7rmNAqvATXj1Ax5s5hipblCfY9zI2eglcPVocCy4YCQ&s=10',
    ),
    PecaRoupa(
      id: '4',
      nome: 'Peça Seleção #4',
      descricao:
          'Quarta peça da sua seleção, trazendo personalidade e acabamento para o visual.',
      categoria: CategoriaPeca.calcados,
      estilo: EstiloPeca.streetwear,
      cor: const Color(0xFF161618),
      ocasiao: 'Urbano',
      preco: 249.90,
      vezesUsada: 9,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcShlwBw38UJ72s9stb6g1bzbkd28ky-wEPsTNvciW7KYw&s=10',
    ),
    PecaRoupa(
      id: '5',
      nome: 'Peça Seleção #5',
      descricao:
          'Quinta peça da sua seleção para finalizar composições com estilo próprio.',
      categoria: CategoriaPeca.acessorios,
      estilo: EstiloPeca.romantico,
      cor: const Color(0xFF3E2B19),
      ocasiao: 'Noite',
      preco: 129.90,
      vezesUsada: 14,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTtu0_k70SH49AhK9dldOTPbziwyyK606LxUGb95puSJg&s',
    ),
    PecaRoupa(
      id: '6',
      nome: 'Peça Seleção #6',
      descricao:
          'Sexta peça da sua seleção, adicionada ao closet para novas combinações.',
      categoria: CategoriaPeca.parteDeCima,
      estilo: EstiloPeca.minimalista,
      cor: const Color(0xFF2D2D2B),
      ocasiao: 'Dia a dia',
      preco: 189.90,
      vezesUsada: 7,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR1EiKUL2PLD3wI27yENCDxM3IG2Uhwv4xJ-rNeh27B3g&s=10',
    ),
    PecaRoupa(
      id: '7',
      nome: 'Peça Seleção #7',
      descricao:
          'Sétima peça da sua seleção, ideal para composições na seção esporte.',
      categoria: CategoriaPeca.parteDeBaixo,
      estilo: EstiloPeca.esportivo,
      cor: const Color(0xFF3E3A34),
      ocasiao: 'Esporte',
      preco: 179.90,
      vezesUsada: 6,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT4jtTxBIMEHrb18vEban-T1Nxlzmcwuby2jGVo9JHlHw&s=10',
    ),
    PecaRoupa(
      id: '8',
      nome: 'Peça Seleção #8',
      descricao:
          'Oitava peça da sua seleção, pensada para compor looks modernos e práticos.',
      categoria: CategoriaPeca.calcados,
      estilo: EstiloPeca.casual,
      cor: const Color(0xFF4A3E2E),
      ocasiao: 'Dia a dia',
      preco: 229.90,
      vezesUsada: 11,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpEZsdFozNMGgAk-sURFNvc7EHnyoYusk5AOLswuqXXw&s=10',
    ),
    PecaRoupa(
      id: '9',
      nome: 'Peça Seleção #9',
      descricao:
          'Nona peça da sua seleção, configurada na seção parte de cima para compor looks.',
      categoria: CategoriaPeca.parteDeCima,
      estilo: EstiloPeca.classico,
      cor: const Color(0xFF6B2332),
      ocasiao: 'Jantar',
      preco: 139.90,
      vezesUsada: 8,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ1stteiUaCpOH--RbV3Q8I5Bh2PiRDUnHHpLOVJBc41Q&s=10',
    ),
    PecaRoupa(
      id: '10',
      nome: 'Peça Seleção #10',
      descricao:
          'Décima peça da sua seleção, configurada na seção esporte com muita versatilidade.',
      categoria: CategoriaPeca.parteDeCima,
      estilo: EstiloPeca.esportivo,
      cor: const Color(0xFF7B3548),
      ocasiao: 'Esporte',
      preco: 199.90,
      vezesUsada: 9,
      origem: 'Guarda-Roupa',
      fotoUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfgSzezqCAUstpb-QD9PuwpDwYFCy__J-FFbE3-LgEbA&s=10',
    ),
  ];

  final List<Look> _looks = [];
  final Map<String, EventoCalendario> _eventos = {};

  @override
  void initState() {
    super.initState();
    _tipoCorpo = _medidas.classificar();
    _cartelaCor = _perfilCor.classificar();

    final look1 = Look(
      id: 'look-1',
      nome: 'Look Seleção #1',
      estilo: EstiloPeca.classico,
      pecas: _pecas.where((p) => ['1', '3', '4', '5'].contains(p.id)).toList(),
      notaIA: 'Combinação montada com as fotos da sua seleção.',
    );
    final look2 = Look(
      id: 'look-2',
      nome: 'Look Seleção #2',
      estilo: EstiloPeca.esportivo,
      pecas: _pecas.where((p) => ['10', '7', '8', '5'].contains(p.id)).toList(),
      notaIA: 'Segunda opção com as peças esportivas da sua seleção.',
    );

    _looks.addAll([look1, look2]);
    _lookSelecionado = look1;

    _eventos[_chave(DateTime.now())] = EventoCalendario(
      id: 'ev-1',
      data: DateTime.now(),
      plano: 'Dia a dia',
      clima: '22° / 16°C',
      look: look1,
    );
  }

  String _chave(DateTime d) => '${d.year}-${d.month}-${d.day}';
  String _brl(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(texto)),
    );
  }

  void _abrirPerfilModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ModalPerfilCorpoCor(
        medidas: _medidas,
        perfilCor: _perfilCor,
        onSalvar: (m, p) {
          setState(() {
            _medidas = m;
            _perfilCor = p;
            _tipoCorpo = m.classificar();
            _cartelaCor = p.classificar();
          });
          _msg('Perfil atualizado: ${_tipoCorpo.label} • ${_cartelaCor.label}');
        },
      ),
    );
  }

  void _salvarLook(Look look, {bool irProvador = false, DateTime? agendarEm}) {
    setState(() {
      _looks.removeWhere((l) => l.id == look.id);
      _looks.insert(0, look);
      _lookSelecionado = look;

      if (agendarEm != null) {
        final k = _chave(agendarEm);
        final atual = _eventos[k];
        _eventos[k] = EventoCalendario(
          id: atual?.id ?? '${DateTime.now().millisecondsSinceEpoch}',
          data: agendarEm,
          plano: atual?.plano ?? 'Look agendado',
          clima: atual?.clima ?? '22° / 16°C',
          look: look,
          usado: atual?.usado ?? false,
        );
      }

      if (irProvador) _aba = 2;
      if (agendarEm != null) _aba = 3;
    });
    _msg(agendarEm != null
        ? 'Look salvo e agendado!'
        : 'Look "${look.nome}" salvo!');
  }

  void _alternarUsado(DateTime dia) {
    final k = _chave(dia);
    final ev = _eventos[k];
    if (ev == null || ev.look == null) return;
    final marcar = !ev.usado;
    final delta = marcar ? 1 : -1;

    setState(() {
      ev.usado = marcar;
      for (final p in ev.look!.pecas) {
        final idx = _pecas.indexWhere((item) => item.id == p.id);
        if (idx != -1) {
          _pecas[idx].vezesUsada = max(0, _pecas[idx].vezesUsada + delta);
        }
      }
    });
    _msg(marcar ? 'Uso registrado nas estatísticas!' : 'Uso desmarcado.');
  }

  @override
  Widget build(BuildContext context) {
    final ativas = _pecas.where((p) => !p.isWishlist).toList();

    final telas = [
      _ClosetTab(
        todasPecas: _pecas,
        looks: _looks,
        brl: _brl,
        onAdicionar: (novas) {
          setState(() => _pecas.insertAll(0, novas));
          _msg('Peça(s) adicionada(s) ao Dress Me.');
        },
        onRemover: (id) =>
            setState(() => _pecas.removeWhere((p) => p.id == id)),
        onMoverParaCloset: (id) {
          setState(() {
            final i = _pecas.indexWhere((p) => p.id == id);
            if (i != -1) {
              final p = _pecas[i];
              _pecas[i] = PecaRoupa(
                id: p.id,
                nome: p.nome,
                descricao: p.descricao,
                categoria: p.categoria,
                estilo: p.estilo,
                cor: p.cor,
                ocasiao: p.ocasiao,
                preco: p.preco,
                vezesUsada: p.vezesUsada,
                origem: p.origem,
                isWishlist: false,
                assetPath: p.assetPath,
                fotoUrl: p.fotoUrl,
                fotoBytes: p.fotoBytes,
              );
            }
          });
          _msg('Movido para o guarda-roupa.');
        },
        onVestirProvador: (look) => setState(() {
          _lookSelecionado = look;
          _aba = 2;
        }),
      ),
      _EstilistaTab(
        pecas: ativas,
        tipoCorpo: _tipoCorpo,
        cartelaCor: _cartelaCor,
        brl: _brl,
        onSalvarLook: _salvarLook,
      ),
      _ProvadorTab(
        lookInicial:
            _lookSelecionado ?? (_looks.isNotEmpty ? _looks.first : null),
        pecas: ativas,
        tipoCorpo: _tipoCorpo,
        brl: _brl,
        onSalvarLook: _salvarLook,
      ),
      _CalendarioTab(
        eventos: _eventos,
        looks: _looks,
        onSalvarEvento: (dia, look, plano, clima) {
          setState(() {
            _eventos[_chave(dia)] = EventoCalendario(
              id: _eventos[_chave(dia)]?.id ??
                  '${DateTime.now().millisecondsSinceEpoch}',
              data: dia,
              plano: plano.isEmpty ? 'Dia livre' : plano,
              clima: clima,
              look: look,
              usado: _eventos[_chave(dia)]?.usado ?? false,
            );
          });
          _msg('Calendário atualizado.');
        },
        onAlternarUsado: _alternarUsado,
      ),
      _EstatisticasTab(
        pecas: ativas,
        looksCount: _looks.length,
        brl: _brl,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dress Me'),
        actions: [
          TextButton.icon(
            onPressed: _abrirPerfilModal,
            icon: const Icon(Icons.tune, size: 16),
            label: Text('${_tipoCorpo.label} • ${_cartelaCor.label}'),
          ),
        ],
      ),
      body: telas[_aba],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE9E6E0))),
        ),
        child: NavigationBar(
          height: 66,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF3F0EB),
          selectedIndex: _aba,
          onDestinationSelected: (i) => setState(() => _aba = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(Icons.checkroom),
              label: 'Closet',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Estilista',
            ),
            NavigationDestination(
              icon: Icon(Icons.accessibility_new_outlined),
              selectedIcon: Icon(Icons.accessibility_new),
              label: 'Provador',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. CLOSET
// ============================================================================

class _ClosetTab extends StatefulWidget {
  final List<PecaRoupa> todasPecas;
  final List<Look> looks;
  final String Function(double) brl;
  final Function(List<PecaRoupa>) onAdicionar;
  final Function(String) onRemover;
  final Function(String) onMoverParaCloset;
  final Function(Look) onVestirProvador;

  const _ClosetTab({
    required this.todasPecas,
    required this.looks,
    required this.brl,
    required this.onAdicionar,
    required this.onRemover,
    required this.onMoverParaCloset,
    required this.onVestirProvador,
  });

  @override
  State<_ClosetTab> createState() => _ClosetTabState();
}

class _ClosetTabState extends State<_ClosetTab> {
  int _subAba = 0;
  CategoriaPeca? _cat;
  EstiloPeca? _estilo;
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final base = _subAba == 1
        ? widget.todasPecas.where((p) => p.isWishlist).toList()
        : widget.todasPecas.where((p) => !p.isWishlist).toList();

    final filtradas = base.where((p) {
      final okCat = _cat == null || p.categoria == _cat;
      final okEst = _estilo == null || p.estilo == _estilo;
      final okBusca = _busca.trim().isEmpty ||
          p.nome.toLowerCase().contains(_busca.toLowerCase()) ||
          p.descricao.toLowerCase().contains(_busca.toLowerCase()) ||
          p.origem.toLowerCase().contains(_busca.toLowerCase());
      return okCat && okEst && okBusca;
    }).toList();

    return _ConteudoCentralizado(
      maxWidth: 720,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Peças')),
                    ButtonSegment(value: 1, label: Text('Desejos')),
                    ButtonSegment(value: 2, label: Text('Looks')),
                  ],
                  selected: {_subAba},
                  onSelectionChanged: (s) => setState(() => _subAba = s.first),
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                ),
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _ModalCadastro(
                      onSalvar: widget.onAdicionar,
                      brl: widget.brl,
                    ),
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                  label: const Text('Nova Peça'),
                  style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
          if (_subAba == 2)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.looks.length,
                itemBuilder: (context, i) {
                  final l = widget.looks[i];
                  return GestureDetector(
                    onTap: () => widget.onVestirProvador(l),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE9E6E0)),
                      ),
                      child: Column(
                        children: [
                          Expanded(child: ColagemLookWidget(look: l)),
                          const SizedBox(height: 6),
                          Text(
                            l.nome,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                          const SizedBox(height: 4),
                          _TagEstilo(estilo: l.estilo),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                textAlign: TextAlign.center,
                onChanged: (v) => setState(() => _busca = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por peça, descrição ou loja...',
                  hintStyle: Theme.of(context).textTheme.bodySmall,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE9E6E0)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Pill(
                      label: 'Todas',
                      ativo: _cat == null,
                      onTap: () => setState(() => _cat = null)),
                  ...CategoriaPeca.values.map(
                    (c) => _Pill(
                      label: c.label,
                      ativo: _cat == c,
                      onTap: () => setState(() => _cat = _cat == c ? null : c),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Pill(
                    label: 'Todos Estilos',
                    ativo: _estilo == null,
                    onTap: () => setState(() => _estilo = null),
                  ),
                  ...EstiloPeca.values.map(
                    (e) => _Pill(
                      label: e.label,
                      ativo: _estilo == e,
                      onTap: () =>
                          setState(() => _estilo = _estilo == e ? null : e),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtradas.length,
                itemBuilder: (context, i) {
                  final p = filtradas[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9E6E0)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FotoPecaWidget(peca: p, fit: BoxFit.cover),
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: p.cor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black26),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.9),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.delete_outline,
                                          size: 15),
                                      onPressed: () => widget.onRemover(p.id),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                p.nome,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                p.descricao,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  _TagEstilo(estilo: p.estilo),
                                  Text(
                                    widget.brl(p.preco),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                p.isWishlist
                                    ? p.origem
                                    : '${p.vezesUsada}x • CPW ${widget.brl(p.custoPorUso)}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 10),
                              ),
                              if (p.isWishlist)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: InkWell(
                                    onTap: () =>
                                        widget.onMoverParaCloset(p.id),
                                    child: const Text(
                                      'Mover para closet',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 2. ESTILISTA IA
// ============================================================================

class _EstilistaTab extends StatefulWidget {
  final List<PecaRoupa> pecas;
  final TipoCorpo tipoCorpo;
  final CartelaCor cartelaCor;
  final String Function(double) brl;
  final Function(Look, {bool irProvador, DateTime? agendarEm}) onSalvarLook;

  const _EstilistaTab({
    required this.pecas,
    required this.tipoCorpo,
    required this.cartelaCor,
    required this.brl,
    required this.onSalvarLook,
  });

  @override
  State<_EstilistaTab> createState() => _EstilistaTabState();
}

class _EstilistaTabState extends State<_EstilistaTab> {
  String _clima = 'Ameno • 22°C';
  String _plano = 'Passeio';
  EstiloPeca _estilo = EstiloPeca.classico;
  PecaRoupa? _pecaBase;
  int _diaOffset = 0;
  Look? _lookGerado;

  void _gerar() {
    if (widget.pecas.isEmpty) return;
    final escolhidas = <PecaRoupa>[];
    final categoriasUsadas = <CategoriaPeca>{};

    if (_pecaBase != null) {
      escolhidas.add(_pecaBase!);
      categoriasUsadas.add(_pecaBase!.categoria);
    }

    for (final cat in CategoriaPeca.values) {
      if (categoriasUsadas.contains(cat) && cat != CategoriaPeca.acessorios) {
        continue;
      }
      final candidatos = widget.pecas
          .where((p) => p.categoria == cat && !escolhidas.contains(p))
          .toList();
      if (candidatos.isEmpty) continue;
      candidatos.sort((a, b) =>
          (b.estilo == _estilo ? 1 : 0).compareTo(a.estilo == _estilo ? 1 : 0));
      escolhidas.add(candidatos.first);
      if (cat == CategoriaPeca.acessorios && candidatos.length > 1) {
        escolhidas.add(candidatos[1]);
      }
    }

    setState(() {
      _lookGerado = Look(
        id: 'ia-${DateTime.now().millisecondsSinceEpoch}',
        nome: '${_estilo.label} • ${_diaOffset == 0 ? 'Hoje' : '+${_diaOffset}d'}',
        estilo: _estilo,
        pecas: escolhidas,
        notaIA:
            '$_clima • $_plano • ${widget.tipoCorpo.label} • ${widget.cartelaCor.label}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataAlvo = DateTime.now().add(Duration(days: _diaOffset));

    return _ConteudoCentralizado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9E6E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Estilista IA',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (i) {
                      final d = DateTime.now().add(Duration(days: i));
                      return _Pill(
                        label: i == 0
                            ? 'Hoje (${d.day}/${d.month})'
                            : '${d.day}/${d.month}',
                        ativo: _diaOffset == i,
                        onTap: () => setState(() => _diaOffset = i),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _clima,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Clima',
                            isDense: true,
                            border: OutlineInputBorder()),
                        items: const ['Ameno • 22°C', 'Quente • 30°C', 'Frio • 13°C']
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _clima = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _plano,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Planos',
                            isDense: true,
                            border: OutlineInputBorder()),
                        items: const ['Passeio', 'Trabalho', 'Jantar', 'Dia a dia']
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setState(() => _plano = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PecaRoupa?>(
                  value: _pecaBase,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Peça inicial (opcional — a IA completa)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<PecaRoupa?>(
                        value: null,
                        child: Text('Escolher todas as peças pela IA')),
                    ...widget.pecas.map((p) => DropdownMenuItem<PecaRoupa?>(
                        value: p, child: Text(p.nome))),
                  ],
                  onChanged: (v) => setState(() => _pecaBase = v),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: EstiloPeca.values
                        .map((e) => _Pill(
                            label: e.label,
                            ativo: _estilo == e,
                            onTap: () => setState(() => _estilo = e)))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _gerar,
                    icon: const Icon(Icons.auto_awesome, size: 17),
                    label: const Text('Gerar Look'),
                  ),
                ),
              ],
            ),
          ),
          if (_lookGerado != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E6E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(_lookGerado!.nome,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  _TagEstilo(estilo: _lookGerado!.estilo),
                  const SizedBox(height: 6),
                  Text(_lookGerado!.notaIA,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 280,
                    child: ColagemLookWidget(look: _lookGerado!, height: 260),
                  ),
                  const SizedBox(height: 12),
                  ..._lookGerado!.pecas.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${p.nome}: ${p.descricao}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              widget.onSalvarLook(_lookGerado!, irProvador: true),
                          child: const Text('Provador'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => widget.onSalvarLook(_lookGerado!,
                              agendarEm: dataAlvo),
                          child: const Text('Salvar & Agendar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 3. PROVADOR / CREATE OUTFIT
// ============================================================================

class _ProvadorTab extends StatefulWidget {
  final Look? lookInicial;
  final List<PecaRoupa> pecas;
  final TipoCorpo tipoCorpo;
  final String Function(double) brl;
  final Function(Look, {bool irProvador, DateTime? agendarEm}) onSalvarLook;

  const _ProvadorTab({
    required this.lookInicial,
    required this.pecas,
    required this.tipoCorpo,
    required this.brl,
    required this.onSalvarLook,
  });

  @override
  State<_ProvadorTab> createState() => _ProvadorTabState();
}

class _ProvadorTabState extends State<_ProvadorTab> {
  late List<PecaRoupa> _vestidas;
  CategoriaPeca _cat = CategoriaPeca.parteDeCima;

  @override
  void initState() {
    super.initState();
    _vestidas =
        widget.lookInicial != null && widget.lookInicial!.pecas.isNotEmpty
            ? List.from(widget.lookInicial!.pecas)
            : widget.pecas.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = widget.pecas.where((p) => p.categoria == _cat).toList();
    final pecaSelecionadaDaCat = _vestidas.firstWhere(
      (p) => p.categoria == _cat,
      orElse: () => opcoes.isNotEmpty ? opcoes.first : widget.pecas.first,
    );
    final lookAtual = Look(
      id: 'provador-atual',
      nome: 'Outfit Criado',
      estilo: EstiloPeca.classico,
      pecas: _vestidas,
    );

    return _ConteudoCentralizado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE9E6E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Provador • ${widget.tipoCorpo.label}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  width: 300,
                  child: ColagemLookWidget(look: lookAtual, height: 290),
                ),
                const SizedBox(height: 10),
                Text(
                  pecaSelecionadaDaCat.nome,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  pecaSelecionadaDaCat.descricao,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: CategoriaPeca.values
                  .map((c) => _Pill(
                      label: c.label,
                      ativo: _cat == c,
                      onTap: () => setState(() => _cat = c)))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 148,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: opcoes.length,
              itemBuilder: (context, i) {
                final p = opcoes[i];
                final ativa = _vestidas.any((item) => item.id == p.id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (p.categoria == CategoriaPeca.acessorios) {
                      if (ativa) {
                        _vestidas.removeWhere((item) => item.id == p.id);
                      } else {
                        if (_vestidas
                                .where((x) =>
                                    x.categoria == CategoriaPeca.acessorios)
                                .length >=
                            2) {
                          final primeiro = _vestidas.firstWhere((x) =>
                              x.categoria == CategoriaPeca.acessorios);
                          _vestidas.remove(primeiro);
                        }
                        _vestidas.add(p);
                      }
                    } else {
                      _vestidas.removeWhere(
                          (item) => item.categoria == p.categoria);
                      _vestidas.add(p);
                    }
                  }),
                  child: Container(
                    width: 126,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ativa ? const Color(0xFFF3F0EB) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ativa
                            ? const Color(0xFF1A1A1D)
                            : const Color(0xFFE9E6E0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FotoPecaWidget(
                            peca: p,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.nome,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          p.descricao,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 9.5, color: Color(0xFF6D6D73)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onSalvarLook(
                    Look(
                        id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                        nome: 'Outfit Criado',
                        estilo: EstiloPeca.classico,
                        pecas: _vestidas),
                  ),
                  child: const Text('Salvar Look'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onSalvarLook(
                    Look(
                        id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                        nome: 'Outfit Criado',
                        estilo: EstiloPeca.classico,
                        pecas: _vestidas),
                    agendarEm: DateTime.now(),
                  ),
                  child: const Text('Colocar no Calendário'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. CALENDÁRIO
// ============================================================================

class _CalendarioTab extends StatefulWidget {
  final Map<String, EventoCalendario> eventos;
  final List<Look> looks;
  final Function(DateTime dia, Look? look, String plano, String clima)
      onSalvarEvento;
  final Function(DateTime dia) onAlternarUsado;

  const _CalendarioTab({
    required this.eventos,
    required this.looks,
    required this.onSalvarEvento,
    required this.onAlternarUsado,
  });

  @override
  State<_CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<_CalendarioTab> {
  DateTime _dia = DateTime.now();
  final _planoCtrl = TextEditingController();
  Look? _lookEscolhido;

  String _chave(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _carregar(DateTime d) {
    final ev = widget.eventos[_chave(d)];
    _planoCtrl.text = ev?.plano ?? '';
    _lookEscolhido =
        ev?.look ?? (widget.looks.isNotEmpty ? widget.looks.first : null);
  }

  @override
  void initState() {
    super.initState();
    _carregar(_dia);
  }

  @override
  Widget build(BuildContext context) {
    final dias =
        List.generate(14, (i) => DateTime.now().add(Duration(days: i)));
    final atual = widget.eventos[_chave(_dia)];

    return _ConteudoCentralizado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dias.length,
              itemBuilder: (context, i) {
                final d = dias[i];
                final sel = _chave(d) == _chave(_dia);
                return GestureDetector(
                  onTap: () => setState(() {
                    _dia = d;
                    _carregar(d);
                  }),
                  child: Container(
                    width: 56,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF1A1A1D) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE9E6E0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${d.day}/${d.month}',
                            style: TextStyle(
                                fontSize: 11,
                                color: sel
                                    ? Colors.white70
                                    : const Color(0xFF6D6D73))),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFF151517))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9E6E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${_dia.day}/${_dia.month}/${_dia.year}',
                    style: Theme.of(context).textTheme.titleMedium),
                if (atual?.look != null) ...[
                  const SizedBox(height: 6),
                  FilterChip(
                    label: Text(atual!.usado ? 'Usado ✓' : 'Marcar usado'),
                    selected: atual.usado,
                    onSelected: (_) => widget.onAlternarUsado(_dia),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _planoCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Planos do dia', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Look?>(
                  value: _lookEscolhido,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Look no calendário',
                      border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<Look?>(
                        value: null, child: Text('Nenhum')),
                    ...widget.looks.map((l) =>
                        DropdownMenuItem<Look?>(value: l, child: Text(l.nome))),
                  ],
                  onChanged: (v) => setState(() => _lookEscolhido = v),
                ),
                if (_lookEscolhido != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 240,
                    child:
                        ColagemLookWidget(look: _lookEscolhido!, height: 210),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () => widget.onSalvarEvento(_dia,
                        _lookEscolhido, _planoCtrl.text.trim(), '22° / 16°C'),
                    child: const Text('Salvar no Calendário'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. ESTATÍSTICAS
// ============================================================================

class _EstatisticasTab extends StatelessWidget {
  final List<PecaRoupa> pecas;
  final int looksCount;
  final String Function(double) brl;

  const _EstatisticasTab({
    required this.pecas,
    required this.looksCount,
    required this.brl,
  });

  @override
  Widget build(BuildContext context) {
    final total = pecas.fold<double>(0, (acc, p) => acc + p.preco);
    final usos = pecas.fold<int>(0, (acc, p) => acc + p.vezesUsada);
    final cpw = usos == 0 ? total : total / usos;
    final porEstilo = <EstiloPeca, double>{};
    for (final p in pecas) {
      porEstilo[p.estilo] = (porEstilo[p.estilo] ?? 0) + p.preco;
    }

    return _ConteudoCentralizado(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _CardResumo(
                    titulo: 'Valor do Closet',
                    valor: brl(total),
                    sub: '${pecas.length} peças • $looksCount looks'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardResumo(
                    titulo: 'CPW Médio',
                    valor: brl(cpw),
                    sub: '$usos usos registrados'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9E6E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Gastos por Estilo',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...EstiloPeca.values.map((e) {
                  final g = porEstilo[e] ?? 0;
                  final pct =
                      total == 0 ? 0.0 : (g / total).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.label,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '${brl(g)} (${(pct * 100).toStringAsFixed(0)}%)',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFFF3F0EB),
                            color: e.textoChip),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MODAIS
// ============================================================================

class _ModalPerfilCorpoCor extends StatefulWidget {
  final MedidasCorporais medidas;
  final PerfilColoracao perfilCor;
  final Function(MedidasCorporais, PerfilColoracao) onSalvar;

  const _ModalPerfilCorpoCor({
    required this.medidas,
    required this.perfilCor,
    required this.onSalvar,
  });

  @override
  State<_ModalPerfilCorpoCor> createState() => _ModalPerfilCorpoCorState();
}

class _ModalPerfilCorpoCorState extends State<_ModalPerfilCorpoCor> {
  late final _ombros =
      TextEditingController(text: widget.medidas.ombros.toStringAsFixed(0));
  late final _busto =
      TextEditingController(text: widget.medidas.busto.toStringAsFixed(0));
  late final _cintura =
      TextEditingController(text: widget.medidas.cintura.toStringAsFixed(0));
  late final _quadril =
      TextEditingController(text: widget.medidas.quadril.toStringAsFixed(0));
  late String _subtom = widget.perfilCor.subtom;
  late String _contraste = widget.perfilCor.contraste;

  MedidasCorporais _lerMedidas() => MedidasCorporais(
        ombros: double.tryParse(_ombros.text.replaceAll(',', '.')) ?? 94,
        busto: double.tryParse(_busto.text.replaceAll(',', '.')) ?? 90,
        cintura: double.tryParse(_cintura.text.replaceAll(',', '.')) ?? 68,
        quadril: double.tryParse(_quadril.text.replaceAll(',', '.')) ?? 95,
      );

  PerfilColoracao _lerCor() =>
      PerfilColoracao(subtom: _subtom, contraste: _contraste);

  @override
  Widget build(BuildContext context) {
    final m = _lerMedidas();
    final c = _lerCor();
    final tipo = m.classificar();
    final paleta = c.classificar();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: _ConteudoCentralizado(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Medidas & Paleta Pessoal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _ombros,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Ombros (cm)',
                              isDense: true,
                              border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _busto,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Busto (cm)',
                              isDense: true,
                              border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _cintura,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Cintura (cm)',
                              isDense: true,
                              border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _quadril,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'Quadril (cm)',
                              isDense: true,
                              border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F1),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text('Biotipo: ${tipo.label}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(tipo.dica,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _subtom,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Subtom',
                          isDense: true,
                          border: OutlineInputBorder()),
                      items: const ['Quente', 'Frio', 'Neutro']
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _subtom = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _contraste,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Contraste',
                          isDense: true,
                          border: OutlineInputBorder()),
                      items: const ['Baixo', 'Médio', 'Alto']
                          .map((x) =>
                              DropdownMenuItem(value: x, child: Text(x)))
                          .toList(),
                      onChanged: (v) => setState(() => _contraste = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F1),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text('Paleta: ${paleta.label}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: paleta.cores
                          .map((cor) => Container(
                              width: 15,
                              height: 15,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                  color: cor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black26))))
                          .toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(paleta.resumo,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  widget.onSalvar(m, c);
                  Navigator.pop(context);
                },
                child: const Text('Salvar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalCadastro extends StatefulWidget {
  final Function(List<PecaRoupa>) onSalvar;
  final String Function(double) brl;

  const _ModalCadastro({required this.onSalvar, required this.brl});

  @override
  State<_ModalCadastro> createState() => _ModalCadastroState();
}

class _ModalCadastroState extends State<_ModalCadastro> {
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController(text: '149,90');
  final _fotoUrlCtrl = TextEditingController();
  CategoriaPeca _cat = CategoriaPeca.parteDeCima;
  EstiloPeca _estilo = EstiloPeca.streetwear;
  String _origem = 'Guarda-Roupa';
  bool _desejos = false;
  Uint8List? _fotoBytes;

  Future<void> _selecionarFoto() async {
    final bytes = await SeletorImagemNativo.escolherImagemDoDispositivo();
    if (bytes != null) {
      setState(() {
        _fotoBytes = bytes;
        _fotoUrlCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pecaPreview = PecaRoupa(
      id: 'preview',
      nome: _nome.text.isEmpty ? 'Nova peça' : _nome.text,
      descricao: _descricao.text,
      categoria: _cat,
      estilo: _estilo,
      cor: const Color(0xFF1A1A1D),
      ocasiao: 'Casual',
      preco: 0,
      fotoBytes: _fotoBytes,
      fotoUrl: _fotoUrlCtrl.text,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: _ConteudoCentralizado(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nova Peça com Foto e Descrição',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _selecionarFoto,
                  child: SizedBox(
                    width: 140,
                    height: 165,
                    child: Stack(
                      children: [
                        FotoPecaWidget(
                          peca: pecaPreview,
                          width: 140,
                          height: 165,
                        ),
                        const Positioned(
                          bottom: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: Color(0xFF1A1A1D),
                            child: Icon(Icons.photo_camera,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _selecionarFoto,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Escolher Foto Real do Dispositivo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _fotoUrlCtrl,
                onChanged: (v) {
                  setState(() {
                    if (v.isNotEmpty) _fotoBytes = null;
                    final t = v.toLowerCase();
                    if (t.contains('princess')) _origem = 'Princess Polly';
                    if (t.contains('zara')) _origem = 'Zara';
                    if (t.contains('aritzia')) _origem = 'Aritzia';
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Ou cole o link (URL) da foto da peça',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nome,
                decoration: const InputDecoration(
                    labelText: 'Nome da peça',
                    isDense: true,
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descricao,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Descrição da peça (tecido, corte, detalhes)',
                    isDense: true,
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CategoriaPeca>(
                      value: _cat,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Categoria',
                          isDense: true,
                          border: OutlineInputBorder()),
                      items: CategoriaPeca.values
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _cat = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<EstiloPeca>(
                      value: _estilo,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Estilo',
                          isDense: true,
                          border: OutlineInputBorder()),
                      items: EstiloPeca.values
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(e.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _estilo = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _preco,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Valor em Real',
                    prefixText: 'R\$ ',
                    isDense: true,
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Guarda-Roupa')),
                  ButtonSegment(value: true, label: Text('Lista de Desejos')),
                ],
                selected: {_desejos},
                onSelectionChanged: (s) => setState(() => _desejos = s.first),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  final nome = _nome.text.trim().isEmpty
                      ? 'Peça $_origem'
                      : _nome.text.trim();
                  final desc = _descricao.text.trim().isEmpty
                      ? '${_cat.label} de estilo ${_estilo.label} para composições versáteis.'
                      : _descricao.text.trim();
                  final valor =
                      double.tryParse(_preco.text.replaceAll(',', '.')) ??
                          129.90;

                  widget.onSalvar([
                    PecaRoupa(
                      id: '${DateTime.now().millisecondsSinceEpoch}',
                      nome: nome,
                      descricao: desc,
                      categoria: _cat,
                      estilo: _estilo,
                      cor: const Color(0xFF1A1A1D),
                      ocasiao: 'Casual',
                      preco: valor,
                      origem: _origem,
                      isWishlist: _desejos,
                      fotoBytes: _fotoBytes,
                      fotoUrl: _fotoUrlCtrl.text.trim().isEmpty
                          ? null
                          : _fotoUrlCtrl.text.trim(),
                    ),
                  ]);
                  Navigator.pop(context);
                },
                child: const Text('Salvar Peça'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool ativo;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFF1A1A1D) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color:
                    ativo ? const Color(0xFF1A1A1D) : const Color(0xFFE9E6E0)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: ativo ? Colors.white : const Color(0xFF151517)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagEstilo extends StatelessWidget {
  final EstiloPeca estilo;
  const _TagEstilo({required this.estilo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: estilo.fundoChip, borderRadius: BorderRadius.circular(6)),
      child: Text(estilo.label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: estilo.textoChip)),
    );
  }
}

class _CardResumo extends StatelessWidget {
  final String titulo;
  final String valor;
  final String sub;

  const _CardResumo(
      {required this.titulo, required this.valor, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E6E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(valor,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(sub,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
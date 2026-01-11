// lib/about_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const authorName = 'Roberto Cc';
    const githubUrl = 'https://github.com/marotoweb/cajuscan_app';

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o CajuScan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Secção do Autor
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Desenvolvido por'),
            subtitle: const Text(authorName),
          ),
          // Secção do GitHub
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Código Fonte (GitHub)'),
            subtitle: const Text(githubUrl),
            onTap: () => _launchURL(githubUrl),
            trailing: const Icon(Icons.open_in_new),
          ),
          const Divider(),
          // Secção dos Termos de Utilização
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Termos de Utilização e Isenção de Responsabilidade',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Text(
            'Esta aplicação é fornecida "COMO ESTÁ", sem garantias de qualquer tipo, expressas ou implícitas. '
            'Ao utilizar o CajuScan, concorda que o faz por sua conta e risco.\n'
            'Apesar do autor desenvolver este aplicativo para seu uso pessoal, decidiu partilhar o mesmo sem qualquer custo.\n'
            'O autor não se responsabiliza por qualquer eventual mau funcionamento, perda de dados, erros de registo, '
            'ou quaisquer outros danos diretos ou indiretos que possam surgir do uso ou da incapacidade de uso desta aplicação.'
            'É da exclusiva responsabilidade do utilizador verificar a correção dos dados enviados para a aplicação Cashew e garantir a sua conformidade.\n'
            'Ao utilizar esta aplicação, concorda em isentar o autor de qualquer responsabilidade relacionada com o uso do CajuScan.'
            'Se não concorda com estes termos, por favor, não utilize esta aplicação.\n\n'
            'Obrigado por utilizar o CajuScan!',
            textAlign: TextAlign.justify,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Versão da App: $_appVersion',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

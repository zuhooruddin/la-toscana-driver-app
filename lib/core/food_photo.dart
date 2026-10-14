import 'package:flutter/material.dart';

class FoodPhoto extends StatelessWidget {
  const FoodPhoto(this.name, {super.key, this.size = 52});
  final String name;
  final double size;
  static const images = <String, String>{
    '4-stagioni': 'assets/images/food/4-stagioni-3b63b6e183.webp',
    '5-quesos': 'assets/images/food/5-quesos-942a04b655.webp',
    'barbacoa': 'assets/images/food/barbacoa-71bf6279a0.webp',
    'bebida-agua-500ml': 'assets/images/food/bebida-agua-500ml-b79fbc05c6.webp',
    'bebida-aquarius-limon-330ml':
        'assets/images/food/bebida-aquarius-limon-330ml-7ca0bb609b.webp',
    'bebida-aquarius-naranja-330ml':
        'assets/images/food/bebida-aquarius-naranja-330ml-914a5ea638.webp',
    'bebida-coca-cola-330ml':
        'assets/images/food/bebida-coca-cola-330ml-d1058ac294.webp',
    'bebida-coca-cola-zero-330ml':
        'assets/images/food/bebida-coca-cola-zero-330ml-bab6af52f5.webp',
    'bebida-coca-cola-zero-zero-330ml':
        'assets/images/food/bebida-coca-cola-zero-zero-330ml-2f53247863.webp',
    'bebida-fanta-limon-330ml':
        'assets/images/food/bebida-fanta-limon-330ml-8b2d3e4f02.webp',
    'bebida-fanta-naranja-330ml':
        'assets/images/food/bebida-fanta-naranja-330ml-050c48dc7e.webp',
    'bebida-lata-cerveza':
        'assets/images/food/bebida-lata-cerveza-cdc88078d9.webp',
    'bebida-nestea-330ml':
        'assets/images/food/bebida-nestea-330ml-8dec5909fb.webp',
    'bebida-vichy-catalan-250ml':
        'assets/images/food/bebida-vichy-catalan-250ml-261ce37117.webp',
    'bebida-zumo-melocoton':
        'assets/images/food/bebida-zumo-melocoton-319fdfd0bf.webp',
    'bebida-zumo-naranja':
        'assets/images/food/bebida-zumo-naranja-cf0faefe2b.webp',
    'bebida-zumo-pina-200ml':
        'assets/images/food/bebida-zumo-pina-200ml-8185c0bd79.webp',
    'brownie-de-chocolate-con-helado':
        'assets/images/food/brownie-de-chocolate-con-helado-95ebc597dd.webp',
    'calamares-caseros': 'assets/images/food/calamares-caseros-b7762c85db.webp',
    'calzone-clasico-cerrado':
        'assets/images/food/calzone-clasico-cerrado-757e1ad9dd.webp',
    'calzone-de-chocolate-casero':
        'assets/images/food/calzone-de-chocolate-casero-fe62fd6081.webp',
    'canelones-de-carne':
        'assets/images/food/canelones-de-carne-075030c502.webp',
    'carbonara-pizza': 'assets/images/food/carbonara-pizza-15902c302f.webp',
    'category-pasta': 'assets/images/food/category-pasta-0f35c4c3b2.webp',
    'chipirones-a-la-andaluza':
        'assets/images/food/chipirones-a-la-andaluza-a55f1d4ed2.webp',
    'coulant-de-chocolate-con-helado':
        'assets/images/food/coulant-de-chocolate-con-helado-bcd2d327c4.webp',
    'crep-de-nutella-casero':
        'assets/images/food/crep-de-nutella-casero-11c2a81853.webp',
    'crocanti-helado': 'assets/images/food/crocanti-helado-8a1ccc29da.webp',
    'croquetas-unidad': 'assets/images/food/croquetas-unidad-957ecc5dc9.webp',
    'di-casa': 'assets/images/food/di-casa-e2b95aba85.webp',
    'emiliana': 'assets/images/food/emiliana-be63521be6.webp',
    'ensalada-cesar': 'assets/images/food/ensalada-cesar-f8c7888395.webp',
    'ensalada-de-la-casa':
        'assets/images/food/ensalada-de-la-casa-d9304abd09.webp',
    'ensalada-de-rulo-de-cabra':
        'assets/images/food/ensalada-de-rulo-de-cabra-20c8939ade.webp',
    'ensalada-di-mare': 'assets/images/food/ensalada-di-mare-b3c1bb3c2a.webp',
    'ensalada-toscana': 'assets/images/food/ensalada-toscana-2f2e401e61.webp',
    'ensalada-verdi': 'assets/images/food/ensalada-verdi-bc509cad03.webp',
    'helado-1-bola-2-bolas-v-f-c':
        'assets/images/food/helado-1-bola-2-bolas-v-f-c-a5aa9cfff5.webp',
    'lambordia': 'assets/images/food/lambordia-d7a0ba38e3.webp',
    'langostinos-en-panko-4-uds':
        'assets/images/food/langostinos-en-panko-4-uds-8714a0f681.webp',
    'logo': 'assets/images/food/logo-ccf0948a1d.webp',
    'lomo-al-pepe-con-rigatones':
        'assets/images/food/lomo-al-pepe-con-rigatones-0525c3f01a.webp',
    'marinera': 'assets/images/food/marinera-16652370fc.webp',
    'mediterranea': 'assets/images/food/mediterranea-3b4b574274.webp',
    'melanzana': 'assets/images/food/melanzana-9517fa5916.webp',
    'mexicana': 'assets/images/food/mexicana-51c84a52b7.webp',
    'napolitana': 'assets/images/food/napolitana-041d0f1ad3.webp',
    'panna-cotta-casera':
        'assets/images/food/panna-cotta-casera-bcd2d327c4.webp',
    'pasta-agnoleti-7-quesos':
        'assets/images/food/pasta-agnoleti-7-quesos-d27a7f6184.webp',
    'pasta-capeli-fungi-porcini':
        'assets/images/food/pasta-capeli-fungi-porcini-d27a7f6184.webp',
    'pasta-gnocchi-de-patata':
        'assets/images/food/pasta-gnocchi-de-patata-00003295f9.webp',
    'pasta-ravioli-de-carne':
        'assets/images/food/pasta-ravioli-de-carne-bfebeada7f.webp',
    'pasta-rigatone': 'assets/images/food/pasta-rigatone-785475f258.webp',
    'pasta-saccotinos-pera-y-gorgonzola':
        'assets/images/food/pasta-saccotinos-pera-y-gorgonzola-67f038265e.webp',
    'pasta-spaguetti': 'assets/images/food/pasta-spaguetti-e8ea6fd631.webp',
    'pasta-tagliatelle': 'assets/images/food/pasta-tagliatelle-0f35c4c3b2.webp',
    'pasta-tortellini': 'assets/images/food/pasta-tortellini-9495b8471f.webp',
    'patatas-bravas': 'assets/images/food/patatas-bravas-b41eba87ca.webp',
    'patatas-fritas': 'assets/images/food/patatas-fritas-dfc8cfc442.webp',
    'patatas-toscana': 'assets/images/food/patatas-toscana-cb968a4ee3.webp',
    'pepperoni': 'assets/images/food/pepperoni-7d02b9fae7.webp',
    'pierina-de-ajo-y-tomate':
        'assets/images/food/pierina-de-ajo-y-tomate-6d1b23fe49.webp',
    'prosciutto': 'assets/images/food/prosciutto-caed301f60.webp',
    'provoletta-calabresa':
        'assets/images/food/provoletta-calabresa-48229ce8c5.webp',
    'provoletta-con-trufa':
        'assets/images/food/provoletta-con-trufa-94fb4fdb37.webp',
    'provoletta-simple': 'assets/images/food/provoletta-simple-efcd92baf2.webp',
    'rigatone-gratinados':
        'assets/images/food/rigatone-gratinados-508467c166.webp',
    'risotto-fruto-di-mare':
        'assets/images/food/risotto-fruto-di-mare-b1069063f4.webp',
    'risotto-mare-e-monte':
        'assets/images/food/risotto-mare-e-monte-b7608f622b.webp',
    'roma': 'assets/images/food/roma-bef1b2fa1c.webp',
    'rustica-base-pesto':
        'assets/images/food/rustica-base-pesto-85f8f001f4.webp',
    'salmonera': 'assets/images/food/salmonera-97a0ec1f51.webp',
    'siciliana': 'assets/images/food/siciliana-e31fe1d93a.webp',
    'tartar-de-salmon-ahumado':
        'assets/images/food/tartar-de-salmon-ahumado-a337ea9926.webp',
    'tiramisu-casero': 'assets/images/food/tiramisu-casero-f924093b63.webp',
    'tropical': 'assets/images/food/tropical-720b0c4cce.webp',
    'trufas-de-chocolate':
        'assets/images/food/trufas-de-chocolate-0f56980a93.webp',
    'vegetal': 'assets/images/food/vegetal-70d7423c9f.webp',
  };
  @override
  Widget build(BuildContext context) {
    final normalized = name
        .toLowerCase()
        .replaceAll('×', '')
        .replaceAll(RegExp(r'^[0-9]+\s*'), '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final entry = images.entries
        .where(
          (e) =>
              normalized.isNotEmpty &&
              (normalized == e.key ||
                  normalized.startsWith(e.key) ||
                  e.key.startsWith(normalized)),
        )
        .firstOrNull;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: entry == null
          ? Container(
              width: size,
              height: size,
              color: const Color(0xFFFFF1E5),
              child: const Icon(Icons.restaurant, color: Color(0xFFED0824)),
            )
          : Image.asset(
              entry.value,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );
  }
}

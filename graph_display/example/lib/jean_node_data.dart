import 'dart:ui';

import 'package:graph_layout/graph_layout.dart';

// Data copied from https://github.com/d3/d3-plugins/blob/master/graph/data/miserables.json
// and manually cleaned up. See also page 14 of the following paper:
// https://arxiv.org/abs/cond-mat/0308217 .
// TODO: Review this again and ensure the two-character codes have been correctly assigned to each character.
// TODO: Also ensure the human-readable names are identical to those in the paper.
const _jeanNamesCommunities = '''1 Myriel MY
1 Napoleon NP
1 Mlle.Baptistine MB
1 Mme.Magloire ME
1 CountessdeLo CL
1 Geborand GE
1 Champtercier MC
1 Cravatte CV
1 Count SN
1 OldMan GG
2 Labarre JL
2 Valjean JV
3 Marguerite MT
2 Mme.deR MR
2 Isabeau IS
2 Gervais PG
3 Tholomyes FT
3 Listolier LI
3 Fameuil FA
3 Blacheville BL
3 Favourite FV
3 Dahlia DA
3 Zephine ZE
3 Fantine FN
4 Mme.Thenardier TM
4 Thenardier TH
5 Cosette CO
4 Javert JA
0 Fauchelevent FF
2 Bamatabois BM
3 Perpetue SP
2 Simplice SS
2 Scaufflaire SC
2 Woman1 PO
2 Judge JU
2 Champmathieu CH
2 Brevet BR
2 Chenildieu CN
2 Cochepaille CC
4 Pontmercy GP
6 Boulatruelle BZ
4 Eponine EP
4 Anzelma AZ
5 Woman2 LL
0 MotherInnocent MI
0 Gribier GR
7 Jondrette JD
7 Mme.Burgon BU
8 Gavroche GA
5 Gillenormand GI
5 Magnon MN
5 Mlle.Gillenormand MG
5 Mme.Pontmercy MP
5 Mlle.Vaubois MV
5 Lt.Gillenormand TG
8 Marius MA
5 BaronessT BT
8 Mabeuf MM
8 Enjolras EN
8 Combeferre CM
8 Prouvaire JP
8 Feuilly FE
8 Courfeyrac CR
8 Bahorel BA
8 Bossuet BO
8 Joly JO
8 Grantaire GT
9 MotherPlutarch PL
4 Gueulemer GU
4 Babet BB
4 Claquesous QU
4 Montparnasse MO
5 Toussaint TS
10 Child1 XA
10 Child2 XB
4 Brujon BJ
8 Mme.Hucheloup HL''';

const _communityColours = [
  Color(0xFFFFC125),
  Color(0xFFFFBBFF),
  Color(0xFF63B8FF),
  Color(0xFF9AFF9A),
  Color(0xFFFFFF00),
  Color(0xFFFF5050),
  Color(0xFFFFA07A),
  Color(0xFF00FFFF),
  Color(0xFFCDC8B1),
  Color(0xFF7CFC00),
  Color(0xFFBA92FF),
];

Node _characterCodeToNode(String characterCode) =>
    IntegerNode(characterCode.hashCode);

final _metadataSplitList =
    _jeanNamesCommunities.split('\n').map((metadataString) {
  final metadataList = metadataString.split(' ');
  // We are dealing with human-generated data, so this assertion is necessary.
  assert(metadataList.length == 3);
  return metadataList;
});

final nodeToColour = {
  for (final metadata in _metadataSplitList)
    _characterCodeToNode(metadata[2]): _communityColours[int.parse(metadata[0])]
};

final nodeToName = {
  for (final metadata in _metadataSplitList)
    _characterCodeToNode(metadata[2]): metadata[1]
};

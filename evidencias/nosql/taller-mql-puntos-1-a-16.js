// =====================================================================
// TALLER MQL – CONSULTAS, AGREGACIÓN E ÍNDICES EN MONGODB
// Universidad El Bosque – Bases de Datos 2 – Puntos 1 a 16
// Integrantes: David Felipe Bejarano Montes, Samuel Camelo, José Rodríguez
//
// Ejecutar en mongosh (VS Code: clic derecho en la conexión -> Launch MongoDB Shell):
//   load("C:/ruta/taller_bejarano_camelo_rodriguez.js")
// Partes A, B y C usan sample_mflix; la Parte D crea y usa la base taller_parteD.
// Cada parte va en su propio bloque { } para que sus variables no choquen.
// =====================================================================

// #####################################################################
// PARTES A Y B – PUNTOS 1 A 10
// #####################################################################
{
/*
=========================================================
PARTE A – CONSULTAS (find)  y  PARTE B – AGREGACIÓN (aggregate)
Puntos 1 a 10
Base de datos: sample_mflix
Ejecutar en mongosh (Launch MongoDB Shell): load("C:/ruta/taller_partes_A_B.js")
=========================================================
*/

db = db.getSiblingDB("sample_mflix"); // equivale a use("sample_mflix") y funciona con load()

// =======================================================
// PUNTO 1. Drama 2000-2010 con imdb.rating >= 8
// =======================================================
/*
Filtro con AND implícito: genres "Drama" (busca dentro del arreglo), year en
rango [2000, 2010] e imdb.rating >= 8. Proyección solo title, year e imdb.rating
sin _id; orden por rating descendente y 10 resultados. El conteo total se
calcula con countDocuments sobre el mismo filtro, sin limit.
*/
const filtro1 = { genres: "Drama", year: { $gte: 2000, $lte: 2010 }, "imdb.rating": { $gte: 8 } };

print("\n========== PUNTO 1 ==========");
printjson(db.movies.find(filtro1, { _id: 0, title: 1, year: 1, "imdb.rating": 1 })
  .sort({ "imdb.rating": -1 })
  .limit(10)
  .toArray());
print("Conteo total:", db.movies.countDocuments(filtro1));


// =======================================================
// PUNTO 2. Películas con Tom Hanks cuyo director no sea Steven Spielberg
// =======================================================
/*
cast "Tom Hanks" busca el actor dentro del arreglo cast.
directors $ne "Steven Spielberg" sobre un arreglo excluye las películas donde
CUALQUIER director sea Spielberg (también las codirigidas por él).
*/
const filtro2 = { cast: "Tom Hanks", directors: { $ne: "Steven Spielberg" } };

print("\n========== PUNTO 2 ==========");
printjson(db.movies.find(filtro2, { _id: 0, title: 1, year: 1, directors: 1 })
  .sort({ year: 1 })
  .toArray());
print("Conteo:", db.movies.countDocuments(filtro2));


// =======================================================
// PUNTO 3. Exactamente 3 géneros que incluyan Comedy y Romance
// =======================================================
/*
$size: 3 exige que el arreglo tenga exactamente 3 elementos.
$all: ["Comedy", "Romance"] exige que estén LOS DOS, en cualquier orden.
(Con $in bastaría con que estuviera uno de los dos.)
*/
const filtro3 = { genres: { $size: 3, $all: ["Comedy", "Romance"] } };

print("\n========== PUNTO 3 ==========");
printjson(db.movies.find(filtro3, { _id: 0, title: 1, genres: 1 }).limit(10).toArray());
print("Conteo:", db.movies.countDocuments(filtro3));


// =======================================================
// PUNTO 4. Sin campo rated, o rated "UNRATED" / "NOT RATED"
// =======================================================
/*
$or entre: el campo no existe ($exists: false) o su valor está en la lista
($in). Se indica el conteo con countDocuments.
*/
const filtro4 = { $or: [ { rated: { $exists: false } }, { rated: { $in: ["UNRATED", "NOT RATED"] } } ] };

print("\n========== PUNTO 4 ==========");
printjson(db.movies.find(filtro4, { _id: 0, title: 1, rated: 1 }).limit(10).toArray());
print("Conteo:", db.movies.countDocuments(filtro4));


// =======================================================
// PUNTO 5. Títulos que empiezan por "The" y terminan en "Man"
// =======================================================
/*
^ ancla el inicio y $ el final; .* permite cualquier texto en medio.
La opción i ignora mayúsculas y minúsculas.
*/
const filtro5 = { title: { $regex: /^The.*Man$/i } };

print("\n========== PUNTO 5 ==========");
printjson(db.movies.find(filtro5, { _id: 0, title: 1 }).sort({ title: 1 }).toArray());
print("Conteo:", db.movies.countDocuments(filtro5));


// =======================================================
// PUNTO 6. Estadísticas por género (> 500 películas)
// =======================================================
/*
1. $match deja solo ratings numéricos (imdb.rating tiene valores "").
   Va ANTES de $unwind para filtrar primero y desenrollar menos documentos.
2. $unwind crea un documento por cada género de la película.
3. $group cuenta películas y calcula promedio y máximo por género.
4. $match sobre el resultado del group deja los géneros con más de 500.
5. $project redondea el promedio a 2 decimales; $sort ordena por promedio.
*/
print("\n========== PUNTO 6 ==========");
printjson(db.movies.aggregate([
  { $match: { "imdb.rating": { $type: "number" } } },
  { $unwind: "$genres" },
  { $group: { _id: "$genres",
              totalPeliculas: { $sum: 1 },
              promedioRating: { $avg: "$imdb.rating" },
              ratingMaximo: { $max: "$imdb.rating" } } },
  { $match: { totalPeliculas: { $gt: 500 } } },
  { $project: { _id: 0, genero: "$_id", totalPeliculas: 1,
                promedioRating: { $round: ["$promedioRating", 2] }, ratingMaximo: 1 } },
  { $sort: { promedioRating: -1 } }
]).toArray());


// =======================================================
// PUNTO 7. Top 5 directores con más películas de rating >= 7.5 (mínimo 5)
// =======================================================
/*
$match filtra rating >= 7.5 y que exista directors; $unwind separa los
directores; $group cuenta y guarda los títulos con $push; $match deja los de
5 o más; $project recorta la lista a 3 títulos con $slice; $sort + $limit
dan el top 5. Se ordena también por director para que los empates salgan
siempre en el mismo orden.
*/
print("\n========== PUNTO 7 ==========");
printjson(db.movies.aggregate([
  { $match: { "imdb.rating": { $gte: 7.5 }, directors: { $exists: true, $ne: null } } },
  { $unwind: "$directors" },
  { $group: { _id: "$directors", cantidad: { $sum: 1 }, titulos: { $push: "$title" } } },
  { $match: { cantidad: { $gte: 5 } } },
  { $project: { _id: 0, director: "$_id", cantidad: 1, titulos: { $slice: ["$titulos", 3] } } },
  { $sort: { cantidad: -1, director: 1 } },
  { $limit: 5 }
]).toArray());


// =======================================================
// PUNTO 8. Número de películas por década desde 1950
// =======================================================
/*
$match deja los años numéricos desde 1950 (year tiene algunos valores texto).
La década es floor(year / 10) * 10; $concat con "s" da "1950s", "1960s"...
*/
print("\n========== PUNTO 8 ==========");
printjson(db.movies.aggregate([
  { $match: { year: { $gte: 1950, $type: "number" } } },
  { $group: { _id: { $multiply: [{ $floor: { $divide: ["$year", 10] } }, 10] },
              totalPeliculas: { $sum: 1 } } },
  { $sort: { _id: 1 } },
  { $project: { _id: 0, decada: { $concat: [{ $toString: "$_id" }, "s"] }, totalPeliculas: 1 } }
]).toArray());


// =======================================================
// PUNTO 9. Top 10 películas más comentadas ($lookup comments -> movies)
// =======================================================
/*
Se agrupa primero en comments por movie_id (cuenta los comentarios), se
ordena y se dejan las 10 primeras; solo entonces $lookup trae título y año
de movies. Así el $lookup se hace 10 veces y no sobre las 21.349 películas,
que es mucho más rápido y da el mismo resultado.
*/
print("\n========== PUNTO 9 ==========");
printjson(db.comments.aggregate([
  { $group: { _id: "$movie_id", numeroComentarios: { $sum: 1 } } },
  { $sort: { numeroComentarios: -1 } },
  { $limit: 10 },
  { $lookup: { from: "movies", localField: "_id", foreignField: "_id", as: "pelicula" } },
  { $unwind: "$pelicula" },
  { $project: { _id: 0, titulo: "$pelicula.title", anio: "$pelicula.year", numeroComentarios: 1 } }
]).toArray());


// =======================================================
// PUNTO 10. Usuarios (email) con más de 250 comentarios
// =======================================================
/*
$group por email cuenta los comentarios y con $min / $max obtiene la fecha
del primero y del último; $match deja los que tienen más de 250.
*/
print("\n========== PUNTO 10 ==========");
printjson(db.comments.aggregate([
  { $group: { _id: "$email",
              cantidadComentarios: { $sum: 1 },
              primerComentario: { $min: "$date" },
              ultimoComentario: { $max: "$date" } } },
  { $match: { cantidadComentarios: { $gt: 250 } } },
  { $project: { _id: 0, email: "$_id", cantidadComentarios: 1, primerComentario: 1, ultimoComentario: 1 } },
  { $sort: { cantidadComentarios: -1 } }
]).toArray());

print("\nPARTES A Y B FINALIZADAS.");

}

// #####################################################################
// PARTE C – PUNTOS 11 A 14
// #####################################################################
{
/*
=========================================================
PARTE C – ESCRITURA E ÍNDICES
Puntos 11, 12, 13 y 14
Base de datos: sample_mflix
Colección original: movies
Ejecutar en mongosh (Launch MongoDB Shell): load("C:/ruta/taller_parteC.js")
=========================================================
*/

db = db.getSiblingDB("sample_mflix"); // equivale a use("sample_mflix") y funciona con load()

// =======================================================
// PUNTO 11. CREAR COLECCIÓN peliculas_pareja
// =======================================================

/*
JUSTIFICACIÓN:
$match filtra las películas de 2015 y SOLO las que tienen un rating numérico.
Esto es necesario porque imdb.rating tiene valores vacíos (""): en MongoDB un
string es "mayor" que cualquier número al comparar tipos distintos, así que
sin este filtro { $gte: ["", 7.5] } daría true y esas películas quedarían
como "Alta" sin tener rating.

$project deja título, géneros y rating, y calcula categoria con $switch:
- Alta: rating >= 7.5
- Media: rating >= 6 y < 7.5
- Baja: rating < 6

$out guarda el resultado en la colección peliculas_pareja (si existe, la reemplaza).
*/

db.movies.aggregate([
  {
    $match: {
      year: 2015,
      "imdb.rating": { $type: "number" }
    }
  },
  {
    $project: {
      _id: 0,
      titulo: "$title",
      generos: "$genres",
      rating: "$imdb.rating",
      categoria: {
        $switch: {
          branches: [
            { case: { $gte: ["$imdb.rating", 7.5] }, then: "Alta" },
            { case: { $gte: ["$imdb.rating", 6] },   then: "Media" }
          ],
          default: "Baja"
        }
      }
    }
  },
  { $out: "peliculas_pareja" }
]);

print("\n========== PUNTO 11 ==========");
print("Colección peliculas_pareja creada.");
print("Total de películas:", db.peliculas_pareja.countDocuments({}));
print("Por categoría:");
db.peliculas_pareja.aggregate([
  { $group: { _id: "$categoria", cantidad: { $sum: 1 } } },
  { $sort: { _id: 1 } }
]).forEach(printjson);
print("Ejemplo de documentos:");
db.peliculas_pareja.find().limit(5).forEach(printjson);


// =======================================================
// PUNTO 12. ACTUALIZAR PELÍCULAS DE CATEGORÍA MEDIA
// =======================================================

/*
JUSTIFICACIÓN:
updateMany() modifica todos los documentos de categoría "Media".
$set agrega revisado: true y $inc suma 0.1 al rating.
matchedCount = documentos que cumplieron el filtro;
modifiedCount = documentos que realmente cambiaron.
Nota: la categoría no se recalcula; una película con 7.4 queda con 7.5
pero sigue como "Media", porque así lo pide el enunciado.
*/

const resultado12 = db.peliculas_pareja.updateMany(
  { categoria: "Media" },
  { $set: { revisado: true }, $inc: { rating: 0.1 } }
);

print("\n========== PUNTO 12 ==========");
print("matchedCount:", resultado12.matchedCount);
print("modifiedCount:", resultado12.modifiedCount);
print("Ejemplo de películas actualizadas:");
db.peliculas_pareja.find({ categoria: "Media", revisado: true }).limit(5).forEach(printjson);


// =======================================================
// PUNTO 13. ELIMINAR PELÍCULAS DE CATEGORÍA BAJA
// =======================================================

/*
JUSTIFICACIÓN:
deleteMany() elimina todos los documentos con categoria "Baja".
deletedCount indica cuántos se borraron.
*/

const bajasAntes = db.peliculas_pareja.countDocuments({ categoria: "Baja" });
const resultado13 = db.peliculas_pareja.deleteMany({ categoria: "Baja" });

print("\n========== PUNTO 13 ==========");
print("Películas Baja antes de borrar:", bajasAntes);
print("deletedCount:", resultado13.deletedCount);
print("Películas Baja restantes:", db.peliculas_pareja.countDocuments({ categoria: "Baja" }));


// =======================================================
// PUNTO 14. EXPLAIN ANTES Y DESPUÉS DE UN ÍNDICE ESR
// =======================================================

/*
JUSTIFICACIÓN:
Se usa la MISMA consulta del punto 1:
  Drama, año entre 2000 y 2010, imdb.rating >= 8,
  orden por rating descendente, 10 resultados.

Índice compuesto según la regla ESR:
  E (Equality) = genres          -> igualdad "Drama"
  S (Sort)     = imdb.rating: -1 -> campo por el que se ordena
  R (Range)    = year            -> rango 2000-2010
imdb.rating también tiene un rango (>= 8), pero va en la posición de Sort
para que el índice entregue los documentos ya ordenados y no haya SORT en memoria.
Si year fuera antes que imdb.rating, MongoDB tendría que ordenar en memoria.
*/

const nombreIndice = "ix_movies_genres_rating_year";

const filtro1 = {
  genres: "Drama",
  year: { $gte: 2000, $lte: 2010 },
  "imdb.rating": { $gte: 8 }
};
const proyeccion1 = { _id: 0, title: 1, year: 1, "imdb.rating": 1 };
const orden1 = { "imdb.rating": -1 };

// Por si quedó creado en una ejecución anterior
if (db.movies.getIndexes().some(ix => ix.name === nombreIndice)) {
  db.movies.dropIndex(nombreIndice);
}

// Etapas del plan (incluye etapas anidadas en inputStage)
function buscarEtapas(objeto, etapas = []) {
  if (objeto === null || typeof objeto !== "object") return etapas;
  if (typeof objeto.stage === "string") etapas.push(objeto.stage);
  for (const valor of Object.values(objeto)) {
    if (valor !== null && typeof valor === "object") buscarEtapas(valor, etapas);
  }
  return etapas;
}

function resumen(titulo, plan) {
  print(`\n========== PUNTO 14: ${titulo} ==========`);
  print("nReturned:", plan.executionStats.nReturned);
  print("totalKeysExamined:", plan.executionStats.totalKeysExamined);
  print("totalDocsExamined:", plan.executionStats.totalDocsExamined);
  print("executionTimeMillis:", plan.executionStats.executionTimeMillis);
  print("Etapas del plan ganador:", buscarEtapas(plan.queryPlanner.winningPlan).join(" <- "));
}

// ANTES del índice
const antes = db.movies.find(filtro1, proyeccion1).sort(orden1).limit(10).explain("executionStats");
resumen("ANTES", antes);

// CREAR ÍNDICE ESR
db.movies.createIndex({ genres: 1, "imdb.rating": -1, year: 1 }, { name: nombreIndice });
print("\nÍndice", nombreIndice, "creado.");

// DESPUÉS del índice
const despues = db.movies.find(filtro1, proyeccion1).sort(orden1).limit(10).explain("executionStats");
resumen("DESPUÉS", despues);

// ELIMINAR EL ÍNDICE (lo pide el enunciado)
db.movies.dropIndex(nombreIndice);
print("\nÍndice", nombreIndice, "eliminado.");
print("PARTE C FINALIZADA.");

}

// #####################################################################
// PARTE D – PUNTO 15 – CASO 1
// #####################################################################
{
// =====================================================================
// TALLER MQL – PARTE D – PUNTO 15: CASO 1 – PLATAFORMA DE DOMICILIOS
// Ejecutar en mongosh: load("C:/Users/ASUS/Downloads/parteD_caso1.js")
// Crea/recrea solo las colecciones del caso 1 en la base taller_parteD.
// =====================================================================

db = db.getSiblingDB("taller_parteD");
const FECHA_REF = ISODate("2026-11-04T05:00:00Z"); // 4 nov 2026, 00:00 Bogotá. En producción sería new Date().
const DIA = 24 * 3600 * 1000;

// Etapas del plan ganador de un explain (para ver IXSCAN vs COLLSCAN)
function etapas(plan, acc = []) {
  if (plan && typeof plan === "object") {
    if (typeof plan.stage === "string") acc.push(plan.stage);
    for (const v of Object.values(plan)) etapas(v, acc);
  }
  return acc;
}
function resumenExplain(titulo, exp) {
  const q = exp.queryPlanner || (exp.stages && exp.stages[0].$cursor.queryPlanner);
  const st = exp.executionStats || (exp.stages && exp.stages[0].$cursor.executionStats);
  print(`  [explain ${titulo}] plan: ${etapas(q.winningPlan).join(" <- ")}` +
        (st ? ` | docsExaminados: ${st.totalDocsExamined} | nReturned: ${st.nReturned}` : ""));
}

["restaurantes", "resenas", "productos", "clientes", "repartidores", "pedidos"]
  .forEach(c => db.getCollection(c).drop());
print("\n################ PUNTO 15 – CASO 1: DOMICILIOS ################");
// =====================================================================
// CASO 1 – PLATAFORMA DE DOMICILIOS (datos)
// Patrones: Extended Reference, Subset, Computed, Attribute (+ Embebido/Referencia)
// =====================================================================

// ---------- IDs fijos para que los ejemplos sean legibles ----------
const R1 = ObjectId("6720a1b2c3d4e5f601000001"); // La Fonda del Arriero
const R2 = ObjectId("6720a1b2c3d4e5f601000002"); // Wok Bambú
const R3 = ObjectId("6720a1b2c3d4e5f601000003"); // Parrilla El Llanero
const R4 = ObjectId("6720a1b2c3d4e5f601000004"); // Arepas de la 85
const R5 = ObjectId("6720a1b2c3d4e5f601000005"); // Pasta Nonna Lucía
const R6 = ObjectId("6720a1b2c3d4e5f601000006"); // Burger Distrito
const R7 = ObjectId("6720a1b2c3d4e5f601000007"); // Ajiaco & Co
const R8 = ObjectId("6720a1b2c3d4e5f601000008"); // Bandeja Express (Medellín)

const C1 = ObjectId("6720a1b2c3d4e5f602000001"); // Laura Gómez
const C2 = ObjectId("6720a1b2c3d4e5f602000002"); // Mateo Pardo
const D1 = ObjectId("6720a1b2c3d4e5f603000001"); // Andrés Rojas (repartidor)

const P_BANDEJA   = ObjectId("6720a1b2c3d4e5f604000001");
const P_LIMONADA  = ObjectId("6720a1b2c3d4e5f604000002");
const P_PADTHAI   = ObjectId("6720a1b2c3d4e5f604000003");
const P_TE        = ObjectId("6720a1b2c3d4e5f604000004");
const P_AREPA     = ObjectId("6720a1b2c3d4e5f604000005");
const P_PARRILLA  = ObjectId("6720a1b2c3d4e5f604000006");

// ---------- 1. restaurantes: Computed (calificacion) + Subset (resenasRecientes) ----------
// promedio se calcula más abajo con un update de pipeline (suma / total).
const restaurante = (_id, nombre, ciudad, localidad, coords, categorias, total, suma) => ({
  _id, nombre, ciudad, localidad,
  ubicacion: { type: "Point", coordinates: coords },
  categorias, activo: true,
  calificacion: { promedio: null, total, suma },
  resenasRecientes: [],
  schemaVersion: 1
});

db.restaurantes.insertMany([
  restaurante(R1, "La Fonda del Arriero", "Bogotá", "Chapinero",    [-74.0602, 4.6486], ["colombiana", "parrilla"], 52340, 240764),
  restaurante(R2, "Wok Bambú",            "Bogotá", "Usaquén",      [-74.0307, 4.6951], ["asiática"],               8120,  38570),
  restaurante(R3, "Parrilla El Llanero",  "Bogotá", "Kennedy",      [-74.1520, 4.6290], ["parrilla"],               3410,  15004),
  restaurante(R4, "Arepas de la 85",      "Bogotá", "Chapinero",    [-74.0535, 4.6698], ["colombiana", "rápida"],   12950, 61512),
  restaurante(R5, "Pasta Nonna Lucía",    "Bogotá", "Teusaquillo",  [-74.0733, 4.6340], ["italiana"],               2205,  10143),
  restaurante(R6, "Burger Distrito",      "Bogotá", "Suba",         [-74.0836, 4.7410], ["hamburguesas"],           30,    147),   // < 50 reseñas
  restaurante(R7, "Ajiaco & Co",          "Bogotá", "La Candelaria",[-74.0723, 4.5967], ["colombiana"],             640,   2752),
  restaurante(R8, "Bandeja Express",      "Medellín", "El Poblado", [-75.5700, 6.2090], ["colombiana"],             900,   4410)    // otra ciudad
]);
db.restaurantes.updateOne({ _id: R1 }, { $set: { direccion: "Cra 7 # 63-44",
  "calificacion.distribucion": { "1": 600, "2": 900, "3": 2400, "4": 11036, "5": 37404 } } });

// Computed: calcular el promedio a partir de suma y total (update con pipeline)
db.restaurantes.updateMany({}, [
  { $set: { "calificacion.promedio": { $round: [{ $divide: ["$calificacion.suma", "$calificacion.total"] }, 2] } } }
]);

// ---------- 2. resenas: todas las reseñas + Extended Reference al cliente ----------
db.resenas.insertMany([
  { _id: ObjectId("6720a1b2c3d4e5f606000001"), restauranteId: R1, pedidoId: ObjectId("6720a1b2c3d4e5f605000001"),
    cliente: { _id: C1, nombre: "Laura G." }, estrellas: 5, comentario: "Llegó caliente y rápido",
    fecha: ISODate("2026-11-02T23:10:00Z") },
  { _id: ObjectId("6720a1b2c3d4e5f606000002"), restauranteId: R1, pedidoId: ObjectId("6720a1b2c3d4e5f605000099"),
    cliente: { _id: C2, nombre: "Mateo P." }, estrellas: 4, comentario: "Muy buena la bandeja",
    fecha: ISODate("2026-11-02T20:41:00Z") }
]);

// Subset: la ficha del restaurante guarda solo las 10 más recientes
db.restaurantes.updateOne({ _id: R1 }, { $set: { resenasRecientes: [
  { resenaId: ObjectId("6720a1b2c3d4e5f606000001"), cliente: "Laura G.", estrellas: 5,
    comentario: "Llegó caliente y rápido", fecha: ISODate("2026-11-02T23:10:00Z") },
  { resenaId: ObjectId("6720a1b2c3d4e5f606000002"), cliente: "Mateo P.", estrellas: 4,
    comentario: "Muy buena la bandeja", fecha: ISODate("2026-11-02T20:41:00Z") }
] } });

// ---------- 3. productos: Attribute (atributos k/v) ----------
db.productos.insertMany([
  { _id: P_BANDEJA, restauranteId: R1, nombre: "Bandeja paisa", categoria: "platos fuertes",
    precio: NumberDecimal("38900"), disponible: true,
    adiciones: [ { nombre: "Huevo extra", precio: NumberDecimal("3500") },
                 { nombre: "Aguacate",    precio: NumberDecimal("4000") } ],
    atributos: [ { k: "tamano", v: "grande" }, { k: "nivelPicante", v: 0 },
                 { k: "aptoVegano", v: false }, { k: "calorias", v: 1450 } ] },
  { _id: P_LIMONADA, restauranteId: R1, nombre: "Limonada de coco", categoria: "bebidas",
    precio: NumberDecimal("12900"), disponible: true, adiciones: [],
    atributos: [ { k: "tamano", v: "500 ml" }, { k: "aptoVegano", v: true }, { k: "azucar", v: "baja" } ] },
  { _id: P_PADTHAI, restauranteId: R2, nombre: "Pad thai de tofu", categoria: "wok",
    precio: NumberDecimal("32900"), disponible: true,
    adiciones: [ { nombre: "Maní extra", precio: NumberDecimal("2500") } ],
    atributos: [ { k: "nivelPicante", v: 2 }, { k: "aptoVegano", v: true }, { k: "sinGluten", v: true } ] },
  { _id: P_TE, restauranteId: R2, nombre: "Té verde frío", categoria: "bebidas",
    precio: NumberDecimal("8500"), disponible: true, adiciones: [],
    atributos: [ { k: "tamano", v: "400 ml" }, { k: "aptoVegano", v: true } ] },
  { _id: P_AREPA, restauranteId: R4, nombre: "Arepa rellena de carne", categoria: "arepas",
    precio: NumberDecimal("18900"), disponible: true, adiciones: [],
    atributos: [ { k: "nivelPicante", v: 1 }, { k: "aptoVegano", v: false } ] },
  { _id: P_PARRILLA, restauranteId: R3, nombre: "Parrillada para dos", categoria: "parrilla",
    precio: NumberDecimal("55000"), disponible: true, adiciones: [],
    atributos: [ { k: "porciones", v: 2 }, { k: "termino", v: ["medio", "tres cuartos", "bien asado"] } ] }
]);

// ---------- 4. clientes: direcciones embebidas + Computed (estadisticas) ----------
db.clientes.insertMany([
  { _id: C1, nombre: "Laura Gómez", email: "laura.gomez@example.com", telefono: "+57 300 000 0001",
    direcciones: [
      { alias: "Casa", direccion: "Cl 72 # 10-34 apto 501", localidad: "Chapinero", principal: true },
      { alias: "Universidad", direccion: "Av Cra 9 # 131A-02", localidad: "Usaquén", principal: false } ],
    estadisticas: { totalPedidos: 37, totalGastado: NumberDecimal("2148300"), ultimoPedido: ISODate("2026-11-02T22:15:00Z") } },
  { _id: C2, nombre: "Mateo Pardo", email: "mateo.pardo@example.com", telefono: "+57 300 000 0002",
    direcciones: [ { alias: "Casa", direccion: "Cl 45 # 19-20", localidad: "Teusaquillo", principal: true } ],
    estadisticas: { totalPedidos: 4, totalGastado: NumberDecimal("196500"), ultimoPedido: ISODate("2026-10-30T19:00:00Z") } }
]);

// ---------- 5. repartidores ----------
db.repartidores.insertOne({
  _id: D1, nombre: "Andrés Rojas", vehiculo: { tipo: "moto", placa: "ABC12D" }, estado: "disponible",
  ubicacionActual: { type: "Point", coordinates: [-74.0571, 4.6512] },
  calificacion: { promedio: 4.8, total: 1210, suma: 5808 }
});

// ---------- 6. pedidos: Extended Reference + foto del menú al momento de la compra ----------
const refCliente = { _id: C1, nombre: "Laura Gómez", telefono: "+57 300 000 0001" };
const refRepartidor = { _id: D1, nombre: "Andrés Rojas", placa: "ABC12D" };
const casaLaura = { direccion: "Cl 72 # 10-34 apto 501", localidad: "Chapinero" };

db.pedidos.insertMany([
  { _id: ObjectId("6720a1b2c3d4e5f605000001"), codigo: "PED-2026-000981", fecha: ISODate("2026-11-02T22:15:00Z"),
    estado: "entregado", cliente: refCliente, repartidor: refRepartidor,
    restaurante: { _id: R1, nombre: "La Fonda del Arriero", ciudad: "Bogotá" },
    items: [
      { productoId: P_BANDEJA, nombre: "Bandeja paisa", precioUnitario: NumberDecimal("38900"), cantidad: 1,
        adiciones: [ { nombre: "Huevo extra", precio: NumberDecimal("3500") } ], subtotal: NumberDecimal("42400") },
      { productoId: P_LIMONADA, nombre: "Limonada de coco", precioUnitario: NumberDecimal("12900"), cantidad: 2,
        adiciones: [], subtotal: NumberDecimal("25800") } ],
    direccionEntrega: casaLaura,
    subtotal: NumberDecimal("68200"), costoEnvio: NumberDecimal("5900"), propina: NumberDecimal("3000"),
    total: NumberDecimal("77100"), metodoPago: "tarjeta",
    historialEstados: [ { estado: "creado", fecha: ISODate("2026-11-02T21:40:00Z") },
                        { estado: "entregado", fecha: ISODate("2026-11-02T22:15:00Z") } ] },
  { _id: ObjectId("6720a1b2c3d4e5f605000002"), codigo: "PED-2026-000944", fecha: ISODate("2026-10-28T01:30:00Z"),
    estado: "entregado", cliente: refCliente, repartidor: refRepartidor,
    restaurante: { _id: R2, nombre: "Wok Bambú", ciudad: "Bogotá" },
    items: [
      { productoId: P_PADTHAI, nombre: "Pad thai de tofu", precioUnitario: NumberDecimal("32900"), cantidad: 1,
        adiciones: [], subtotal: NumberDecimal("32900") },
      { productoId: P_TE, nombre: "Té verde frío", precioUnitario: NumberDecimal("8500"), cantidad: 1,
        adiciones: [], subtotal: NumberDecimal("8500") } ],
    direccionEntrega: casaLaura,
    subtotal: NumberDecimal("41400"), costoEnvio: NumberDecimal("4900"), propina: NumberDecimal("2000"),
    total: NumberDecimal("48300"), metodoPago: "nequi",
    historialEstados: [ { estado: "creado", fecha: ISODate("2026-10-28T00:55:00Z") },
                        { estado: "entregado", fecha: ISODate("2026-10-28T01:30:00Z") } ] },
  { _id: ObjectId("6720a1b2c3d4e5f605000003"), codigo: "PED-2026-000902", fecha: ISODate("2026-10-20T18:05:00Z"),
    estado: "entregado", cliente: refCliente, repartidor: refRepartidor,
    restaurante: { _id: R4, nombre: "Arepas de la 85", ciudad: "Bogotá" },
    items: [
      { productoId: P_AREPA, nombre: "Arepa rellena de carne", precioUnitario: NumberDecimal("18900"), cantidad: 2,
        adiciones: [], subtotal: NumberDecimal("37800") } ],
    direccionEntrega: casaLaura,
    subtotal: NumberDecimal("37800"), costoEnvio: NumberDecimal("3900"), propina: NumberDecimal("0"),
    total: NumberDecimal("41700"), metodoPago: "efectivo",
    historialEstados: [ { estado: "creado", fecha: ISODate("2026-10-20T17:30:00Z") },
                        { estado: "entregado", fecha: ISODate("2026-10-20T18:05:00Z") } ] },
  { _id: ObjectId("6720a1b2c3d4e5f605000004"), codigo: "PED-2026-000871", fecha: ISODate("2026-10-15T23:00:00Z"),
    estado: "cancelado", cliente: refCliente, repartidor: null,
    restaurante: { _id: R3, nombre: "Parrilla El Llanero", ciudad: "Bogotá" },
    items: [
      { productoId: P_PARRILLA, nombre: "Parrillada para dos", precioUnitario: NumberDecimal("55000"), cantidad: 1,
        adiciones: [], subtotal: NumberDecimal("55000") } ],
    direccionEntrega: casaLaura,
    subtotal: NumberDecimal("55000"), costoEnvio: NumberDecimal("5900"), propina: NumberDecimal("0"),
    total: NumberDecimal("60900"), metodoPago: "tarjeta",
    historialEstados: [ { estado: "creado", fecha: ISODate("2026-10-15T22:50:00Z") },
                        { estado: "cancelado", fecha: ISODate("2026-10-15T23:00:00Z") } ] },
  { _id: ObjectId("6720a1b2c3d4e5f605000005"), codigo: "PED-2026-000655", fecha: ISODate("2026-09-20T19:10:00Z"),
    estado: "entregado", cliente: refCliente, repartidor: refRepartidor,
    restaurante: { _id: R1, nombre: "La Fonda del Arriero", ciudad: "Bogotá" },
    items: [
      { productoId: P_BANDEJA, nombre: "Bandeja paisa", precioUnitario: NumberDecimal("38900"), cantidad: 1,
        adiciones: [], subtotal: NumberDecimal("38900") } ],
    direccionEntrega: casaLaura,
    subtotal: NumberDecimal("38900"), costoEnvio: NumberDecimal("5900"), propina: NumberDecimal("0"),
    total: NumberDecimal("44800"), metodoPago: "tarjeta",
    historialEstados: [ { estado: "creado", fecha: ISODate("2026-09-20T18:40:00Z") },
                        { estado: "entregado", fecha: ISODate("2026-09-20T19:10:00Z") } ] }
]);

// ---------- 7. Índices del caso 1 ----------
db.pedidos.createIndex({ "cliente._id": 1, fecha: -1 }, { name: "ix_pedidos_cliente_fecha" });
db.pedidos.createIndex({ "restaurante._id": 1, fecha: -1 }, { name: "ix_pedidos_restaurante_fecha" });
db.restaurantes.createIndex({ ciudad: 1, activo: 1, "calificacion.promedio": -1, "calificacion.total": -1 },
                            { name: "ix_restaurantes_ranking" });
db.restaurantes.createIndex({ ubicacion: "2dsphere" }, { name: "ix_restaurantes_ubicacion" });
db.resenas.createIndex({ restauranteId: 1, fecha: -1 }, { name: "ix_resenas_restaurante_fecha" });
db.resenas.createIndex({ pedidoId: 1 }, { unique: true, name: "ix_resenas_pedido" });
db.productos.createIndex({ restauranteId: 1, categoria: 1 }, { name: "ix_productos_menu" });
db.productos.createIndex({ "atributos.k": 1, "atributos.v": 1 }, { name: "ix_productos_atributos" });
db.clientes.createIndex({ email: 1 }, { unique: true, name: "ix_clientes_email" });

// ---------- 8. Escritura: nueva reseña (Computed + Subset en UNA operación) ----------
const nueva = { resenaId: ObjectId("6720a1b2c3d4e5f606000003"), cliente: "Sofía R.", estrellas: 5,
                comentario: "La mejor bandeja de Chapinero", fecha: ISODate("2026-11-03T18:20:00Z") };
db.resenas.insertOne({ _id: nueva.resenaId, restauranteId: R1, pedidoId: ObjectId("6720a1b2c3d4e5f605000100"),
  cliente: { _id: ObjectId("6720a1b2c3d4e5f602000003"), nombre: nueva.cliente },
  estrellas: nueva.estrellas, comentario: nueva.comentario, fecha: nueva.fecha });

db.restaurantes.updateOne(
  { _id: R1 },
  [
    { $set: {
        "calificacion.total": { $add: ["$calificacion.total", 1] },
        "calificacion.suma":  { $add: ["$calificacion.suma", nueva.estrellas] },
        ["calificacion.distribucion." + nueva.estrellas]:
          { $add: ["$calificacion.distribucion." + nueva.estrellas, 1] },
        resenasRecientes: { $slice: [{ $concatArrays: [[{ $literal: nueva }], "$resenasRecientes"] }, 10] }
    } },
    { $set: { "calificacion.promedio": { $round: [{ $divide: ["$calificacion.suma", "$calificacion.total"] }, 2] } } }
  ]
);

// ---------- 9. CONSULTA (a): pedidos de un cliente en el último mes con el total pagado ----------
print("\n=== Caso 1 (a) Pedidos de Laura en los últimos 30 días ===");
const hace30dias = new Date(FECHA_REF.getTime() - 30 * DIA); // en producción: new Date(Date.now() - 30*DIA)
printjson(db.pedidos.aggregate([
  { $match: { "cliente._id": C1, fecha: { $gte: hace30dias }, estado: { $ne: "cancelado" } } },
  { $sort: { fecha: -1 } },
  { $facet: {
      pedidos: [ { $project: { _id: 0, codigo: 1, fecha: 1, estado: 1, restaurante: "$restaurante.nombre", total: 1 } } ],
      resumen: [ { $group: { _id: null, cantidadPedidos: { $sum: 1 }, totalPagado: { $sum: "$total" } } },
                 { $project: { _id: 0 } } ]
  } }
]).toArray());
// Esperado: 3 pedidos (000981, 000944, 000902), totalPagado 167100

// ---------- 10. CONSULTA (b): top 5 restaurantes mejor calificados de una ciudad ----------
print("\n=== Caso 1 (b) Top 5 restaurantes de Bogotá ===");
printjson(db.restaurantes.find(
  { ciudad: "Bogotá", activo: true, "calificacion.total": { $gte: 50 } },
  { _id: 0, nombre: 1, localidad: 1, "calificacion.promedio": 1, "calificacion.total": 1 }
).sort({ "calificacion.promedio": -1, "calificacion.total": -1 }).limit(5).toArray());
// Esperado: Arepas de la 85, Wok Bambú, La Fonda del Arriero, Pasta Nonna Lucía, Parrilla El Llanero
// (Burger Distrito queda fuera por tener menos de 50 reseñas; Bandeja Express es de Medellín)

// ---------- 11. Consulta extra (Attribute): platos veganos con picante <= 2 ----------
print("\n=== Caso 1 extra: veganos con picante hasta 2 ===");
printjson(db.productos.find({ atributos: { $all: [
  { $elemMatch: { k: "aptoVegano", v: true } },
  { $elemMatch: { k: "nivelPicante", v: { $lte: 2 } } }
] } }, { _id: 0, nombre: 1, precio: 1 }).toArray());
// Esperado: Pad thai de tofu


// ---------- 12. Documentos de ejemplo (captura del JSON por colección) ----------
print("\n=== Caso 1: un documento de ejemplo por colección ===");
for (const c of ["restaurantes", "resenas", "productos", "clientes", "repartidores", "pedidos"]) {
  print(`\n--- ${c} (${db.getCollection(c).countDocuments()} documentos) ---`);
  printjson(db.getCollection(c).findOne());
}

// ---------- 13. Índices creados (captura) ----------
print("\n=== Caso 1: índices ===");
for (const c of ["restaurantes", "resenas", "productos", "clientes", "pedidos"]) {
  print(`${c}: ` + db.getCollection(c).getIndexes().map(ix => ix.name).join(", "));
}

// ---------- 14. Las consultas usan índice (explain) ----------
print("\n=== Caso 1: explain de las consultas de negocio ===");
resumenExplain("(a) pedidos del cliente",
  db.pedidos.find({ "cliente._id": C1, fecha: { $gte: hace30dias }, estado: { $ne: "cancelado" } })
            .sort({ fecha: -1 }).explain("executionStats"));
resumenExplain("(b) top 5 restaurantes",
  db.restaurantes.find({ ciudad: "Bogotá", activo: true, "calificacion.total": { $gte: 50 } })
                 .sort({ "calificacion.promedio": -1, "calificacion.total": -1 }).limit(5).explain("executionStats"));
print("\nCASO 1 FINALIZADO.");

}

// #####################################################################
// PARTE D – PUNTO 16 – CASO 2
// #####################################################################
{
// =====================================================================
// TALLER MQL – PARTE D – PUNTO 16: CASO 2 – CALIDAD DEL AIRE EN BOGOTÁ (IoT)
// Ejecutar en mongosh: load("C:/Users/ASUS/Downloads/parteD_caso2.js")
// Crea/recrea solo las colecciones del caso 2 en la base taller_parteD.
// La carga simula 1 día (3 sensores x 1.440 minutos); tarda unos segundos.
// =====================================================================

db = db.getSiblingDB("taller_parteD");
const FECHA_REF = ISODate("2026-11-04T05:00:00Z"); // 4 nov 2026, 00:00 Bogotá. En producción sería new Date().
const DIA = 24 * 3600 * 1000;

// Etapas del plan ganador de un explain (para ver IXSCAN vs COLLSCAN)
function etapas(plan, acc = []) {
  if (plan && typeof plan === "object") {
    if (typeof plan.stage === "string") acc.push(plan.stage);
    for (const v of Object.values(plan)) etapas(v, acc);
  }
  return acc;
}
function resumenExplain(titulo, exp) {
  const q = exp.queryPlanner || (exp.stages && exp.stages[0].$cursor.queryPlanner);
  const st = exp.executionStats || (exp.stages && exp.stages[0].$cursor.executionStats);
  print(`  [explain ${titulo}] plan: ${etapas(q.winningPlan).join(" <- ")}` +
        (st ? ` | docsExaminados: ${st.totalDocsExamined} | nReturned: ${st.nReturned}` : ""));
}

["sensores", "lecturas_hora", "alertas"].forEach(c => db.getCollection(c).drop());
print("\n################ PUNTO 16 – CASO 2: CALIDAD DEL AIRE ################");
// =====================================================================
// CASO 2 – CALIDAD DEL AIRE EN BOGOTÁ (IoT)
// Patrones: Bucket, Computed, Schema Versioning (+ Extended Reference)
// =====================================================================

// ---------- 1. sensores (schemaVersion 1 = AQ-200 sin CO2, 2 = AQ-300 con CO2) ----------
const V1 = ["pm25", "pm10", "temp", "hum"];
const V2 = ["pm25", "pm10", "temp", "hum", "co2"];
const sensores = [
  { _id: "SEN-KEN-014", localidad: "Kennedy", estacion: "Parque Timiza",
    ubicacion: { type: "Point", coordinates: [-74.1576, 4.6097] }, modelo: "AQ-200", schemaVersion: 1,
    variables: V1, instalado: ISODate("2024-03-12T15:00:00Z"), activo: true },
  { _id: "SEN-KEN-022", localidad: "Kennedy", estacion: "Biblioteca El Tintal",
    ubicacion: { type: "Point", coordinates: [-74.1540, 4.6420] }, modelo: "AQ-200", schemaVersion: 1,
    variables: V1, instalado: ISODate("2024-05-02T15:00:00Z"), activo: true },
  { _id: "SEN-CHA-003", localidad: "Chapinero", estacion: "Parque de los Hippies",
    ubicacion: { type: "Point", coordinates: [-74.0631, 4.6479] }, modelo: "AQ-300", schemaVersion: 2,
    variables: V2, instalado: ISODate("2026-09-01T14:00:00Z"), reemplazaA: "SEN-CHA-001", activo: true }
];
db.sensores.insertMany(sensores);

// ---------- 2. Índices del caso 2 (antes de cargar: el upsert usa el índice único) ----------
db.lecturas_hora.createIndex({ sensorId: 1, inicio: 1 }, { unique: true, name: "ix_lh_sensor_inicio" });
db.lecturas_hora.createIndex({ localidad: 1, inicio: 1 }, { name: "ix_lh_localidad_inicio" });
db.lecturas_hora.createIndex({ inicio: -1 }, { name: "ix_lh_alertas",
                               partialFilterExpression: { alertasPm25: { $gt: 0 } } });
db.sensores.createIndex({ localidad: 1 }, { name: "ix_sensores_localidad" });
db.sensores.createIndex({ ubicacion: "2dsphere" }, { name: "ix_sensores_ubicacion" });
db.alertas.createIndex({ ts: 1 }, { expireAfterSeconds: 180 * 24 * 3600, name: "ix_alertas_ttl" });
db.alertas.createIndex({ sensorId: 1, ts: -1 }, { name: "ix_alertas_sensor_ts" });

// ---------- 3. Simulación de un día de lecturas (1 por minuto) ----------
// Valores deterministas (sin aleatorios) con picos de tráfico a las 7:30 y 18:30 hora local.
const UMBRAL_PM25 = 37;
const DIA_INICIO = ISODate("2026-11-03T05:00:00Z"); // 3 nov 2026, 00:00 Bogotá
const SIM = { "SEN-KEN-014": { base: 22, factor: 1.0, semilla: 1 },
              "SEN-KEN-022": { base: 19, factor: 0.9, semilla: 4 },
              "SEN-CHA-003": { base: 11, factor: 0.5, semilla: 7 } };
const r1 = (x) => Math.round(x * 10) / 10;

function lecturaSimulada(sensor, minuto) {
  const p = SIM[sensor._id], h = minuto / 60; // h = hora local (0..24)
  const pico = 18 * Math.exp(-((h - 7.5) ** 2) / 4) + 14 * Math.exp(-((h - 18.5) ** 2) / 5);
  const ruido = 3 * Math.sin(minuto * 0.7 + p.semilla) + 2 * Math.sin(minuto * 0.13 + p.semilla * 2);
  const l = { ts: new Date(DIA_INICIO.getTime() + minuto * 60000) };
  l.pm25 = r1(p.base + p.factor * pico + ruido);
  l.pm10 = r1(l.pm25 * 1.6 + 4 * Math.sin(minuto * 0.05 + p.semilla));
  l.temp = r1(13 + 0.4 * Math.sin(p.semilla) + 6 * Math.exp(-((h - 14) ** 2) / 18) + 0.3 * Math.sin(minuto * 0.21));
  l.hum  = Math.round(80 + 2 * Math.cos(p.semilla) - 14 * Math.exp(-((h - 14) ** 2) / 18) + 2 * Math.sin(minuto * 0.17));
  if (sensor.schemaVersion >= 2) l.co2 = Math.round(410 + 60 * pico / 18 + 8 * Math.sin(minuto * 0.3));
  return l;
}

// Bucket + Computed: una operación por lectura. Si el bucket de esa hora no existe, el upsert lo crea.
function opLectura(sensor, l) {
  const inicio = new Date(Math.floor(l.ts.getTime() / 3600000) * 3600000);
  const inc = { nLecturas: 1, alertasPm25: l.pm25 > UMBRAL_PM25 ? 1 : 0 }, min = {}, max = {};
  for (const v of sensor.variables) {
    inc[`resumen.${v}.n`] = 1;
    inc[`resumen.${v}.suma`] = l[v];
    min[`resumen.${v}.min`] = l[v];
    max[`resumen.${v}.max`] = l[v];
  }
  return { updateOne: {
    filter: { sensorId: sensor._id, inicio },
    update: { $push: { lecturas: l }, $inc: inc, $min: min, $max: max,
              $setOnInsert: { localidad: sensor.localidad, schemaVersion: sensor.schemaVersion,
                              fin: new Date(inicio.getTime() + 3600000) } },
    upsert: true } };
}

for (const s of sensores) {
  const ops = [], alertas = [];
  let ultima = null;
  for (let minuto = 0; minuto < 1440; minuto++) {
    const l = lecturaSimulada(s, minuto);
    ops.push(opLectura(s, l));
    if (l.pm25 > UMBRAL_PM25) {
      alertas.push({ sensorId: s._id, localidad: s.localidad, variable: "pm25", valor: l.pm25,
                     umbral: UMBRAL_PM25, ts: l.ts, estado: "abierta" });
    }
    ultima = l;
  }
  db.lecturas_hora.bulkWrite(ops, { ordered: true }); // ordered: cada upsert ve el bucket que creó el anterior
  if (alertas.length) db.alertas.insertMany(alertas);
  db.sensores.updateOne({ _id: s._id }, { $set: { ultimaLectura: ultima } }); // Computed: estado actual
  print(`${s._id}: ${ops.length} lecturas, ${alertas.length} minutos en alerta`);
}
print(`Buckets creados: ${db.lecturas_hora.countDocuments()} (3 sensores x 24 horas = 72)`);

// ---------- 4. CONSULTA (a): promedio horario de PM2.5 de una localidad en un día ----------
print("\n=== Caso 2 (a) Promedio horario de PM2.5 en Kennedy, 3 nov 2026 ===");
printjson(db.lecturas_hora.aggregate([
  { $match: { localidad: "Kennedy",
              inicio: { $gte: ISODate("2026-11-03T05:00:00Z"), $lt: ISODate("2026-11-04T05:00:00Z") } } },
  { $group: { _id: "$inicio",
              sumaPm25: { $sum: "$resumen.pm25.suma" },
              nPm25:    { $sum: "$resumen.pm25.n" },
              maxPm25:  { $max: "$resumen.pm25.max" },
              sensores: { $sum: 1 } } },
  { $sort: { _id: 1 } },
  { $project: { _id: 0,
                hora: { $dateToString: { format: "%H:00", date: "$_id", timezone: "America/Bogota" } },
                promedioPm25: { $round: [{ $divide: ["$sumaPm25", "$nPm25"] }, 1] },
                maxPm25: 1, sensores: 1 } }
]).toArray());

// ---------- 5. CONSULTA (b): sensores que generaron alertas en la última semana ----------
print("\n=== Caso 2 (b) Sensores con alertas en los últimos 7 días ===");
const hace7dias = new Date(FECHA_REF.getTime() - 7 * DIA); // en producción: new Date(Date.now() - 7*DIA)
printjson(db.lecturas_hora.aggregate([
  { $match: { inicio: { $gte: hace7dias }, alertasPm25: { $gt: 0 } } },
  { $group: { _id: "$sensorId",
              localidad:       { $first: "$localidad" },
              minutosEnAlerta: { $sum: "$alertasPm25" },
              horasConAlerta:  { $sum: 1 },
              pm25Max:         { $max: "$resumen.pm25.max" },
              ultimaHora:      { $max: "$inicio" } } },
  { $sort: { minutosEnAlerta: -1 } }
]).toArray());

// ---------- 6. Consulta extra (Schema Versioning): CO2 solo en buckets versión 2 ----------
print("\n=== Caso 2 extra: CO2 promedio (solo sensores v2) ===");
printjson(db.lecturas_hora.aggregate([
  { $match: { schemaVersion: { $gte: 2 }, localidad: "Chapinero" } },
  { $group: { _id: "$sensorId", sumaCo2: { $sum: "$resumen.co2.suma" }, nCo2: { $sum: "$resumen.co2.n" } } },
  { $project: { co2Promedio: { $round: [{ $divide: ["$sumaCo2", "$nCo2"] }, 0] } } }
]).toArray());


// ---------- 8. Documentos de ejemplo (captura del JSON por colección) ----------
print("\n=== Caso 2: documentos de ejemplo ===");
print("\n--- sensores v1 (AQ-200, sin CO2) ---");
printjson(db.sensores.findOne({ schemaVersion: 1 }));
print("\n--- sensores v2 (AQ-300, con CO2) ---");
printjson(db.sensores.findOne({ schemaVersion: 2 }));
// Bucket de la hora pico (7:00 a. m. Bogotá = 12:00Z); se muestran 3 de sus 60 lecturas
const proyBucket = { lecturas: { $slice: 3 } };
print("\n--- lecturas_hora v1 (bucket 7:00 a. m., 3 de 60 lecturas) ---");
printjson(db.lecturas_hora.findOne({ sensorId: "SEN-KEN-014", inicio: ISODate("2026-11-03T12:00:00Z") }, proyBucket));
print("\n--- lecturas_hora v2 (bucket 7:00 a. m., 3 de 60 lecturas) ---");
printjson(db.lecturas_hora.findOne({ sensorId: "SEN-CHA-003", inicio: ISODate("2026-11-03T12:00:00Z") }, proyBucket));
print("\n--- alertas ---");
printjson(db.alertas.findOne());

// ---------- 9. Índices creados (captura) ----------
print("\n=== Caso 2: índices ===");
for (const c of ["sensores", "lecturas_hora", "alertas"]) {
  print(`${c}: ` + db.getCollection(c).getIndexes().map(ix => ix.name).join(", "));
}

// ---------- 10. Las consultas usan índice (explain) ----------
print("\n=== Caso 2: explain de las consultas de negocio ===");
resumenExplain("(a) promedio horario Kennedy",
  db.lecturas_hora.find({ localidad: "Kennedy",
    inicio: { $gte: ISODate("2026-11-03T05:00:00Z"), $lt: ISODate("2026-11-04T05:00:00Z") } }).explain("executionStats"));
resumenExplain("(b) alertas última semana",
  db.lecturas_hora.find({ inicio: { $gte: hace7dias }, alertasPm25: { $gt: 0 } }).explain("executionStats"));
print("\nCASO 2 FINALIZADO.");

}


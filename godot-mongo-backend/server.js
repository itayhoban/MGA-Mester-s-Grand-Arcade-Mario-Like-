const express = require("express")
const mongoose = require("mongoose")
const cors = require("cors")

const app = express()
app.use(express.json())
app.use(cors())

mongoose.connect("mongodb+srv://mongo:Harper!2009@game-cluster.krdfga2.mongodb.net/", {
    useNewUrlParser: true, // Use the modern MongoDB url parser
    useUnifiedTopology: true, // Use the new server engine for better performance
})

const GameDataSchema = new mongoose.Schema({
    time: {
        type: Number,
        set: (v) => Math.round(v)
    },
    lives: Number,
    points: Number,
    coins: Number,
    enemies_killed: Number,
    number_of_jumps: Number,
    death_by_fall: Number,
    pct: Number, // Points * Coins / Time
    ekj: Number, // Enemies killed / Number of jumps
    score: Number,
    difficulty: String,
    timeStamp: {
        type: Date,
        default: Date.now
    }
})

const GameData = mongoose.model("GameData", GameDataSchema)

app.post("/data", async (req, res) => {
    try {
        const gameData = new GameData(req.body)
        await gameData.save()
        res.status(201).send(gameData)
    } catch (error) {
        res.status(400).send({ error: "Failed to save game data" })
    }
})

app.get("/data", async (req, res) => {
    try {
        const gameData = await GameData.find().sort({ timeStamp: -1 }).limit(5000)
        res.status(200).send(gameData)
    } catch (error) {
        res.status(500).send({ error: "Failed to retrieve game data" })
    }
})

app.get("/tableData", async (req, res) => {
    try {
        const gameData = await GameData.find().sort({ timeStamp: -1 }).limit(5000);

        let tableRows = gameData.map((item, index) => {
            const rowColor = index % 2 === 0 ? "red" : "blue"; 
            return `
                <tr style="background-color: ${rowColor}; color: white;">
                    <td>${item.time}</td>
                    <td>${item.lives}</td>
                    <td>${item.points}</td>
                    <td>${item.coins}</td>
                    <td>${item.enemies_killed}</td>
                    <td>${item.number_of_jumps ?? ""}</td>
                    <td>${item.death_by_fall}</td>
                    <td>${item.pct ?? ""}</td>
                    <td>${item.ekj ?? ""}</td>
                    <td>${item.score ?? ""}</td>
                    <td>${item.difficulty ?? ""}</td>
                    <td>${new Date(item.timeStamp).toLocaleString()}</td>
                </tr>
            `;
        }).join("");

        const html = `
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8" />
                <title>Game Data</title>
                <style>
                    h1 {
                        text-align: center;
                    }
                    table {
                        border-collapse: collapse;
                        width: 100%;
                        font-size: 18px;
                    }
                    th, td {
                        border: 1px solid #ddd;
                        padding: 8px;
                        text-align: center;
                    }
                    th {
                        background-color: #333;
                        color: white;
                    }
                </style>
            </head>
            <body>
                <h1>Game Data</h1>
                <table>
                    <tr>
                        <th>Time</th>
                        <th>Lives</th>
                        <th>Points</th>
                        <th>Coins</th>
                        <th>Enemies Killed</th>
                        <th>Number of Jumps</th>
                        <th>Death by Fall</th>
                        <th>PCT</th>
                        <th>EKJ</th>
                        <th>Score</th>
                        <th>Difficulty</th>
                        <th>Timestamp</th>
                    </tr>
                    ${tableRows}
                </table>
            </body>
            </html>
        `;

        res.status(200).send(html);

    } catch (error) {
        res.status(500).send({ error: "Failed to retrieve game data" });
    }
});

app.delete("/data", async (req, res) => {
  try {
    await GameData.deleteMany({})  // deletes all game data records
    res.status(200).send({ message: "All game data deleted" })
  } catch (error) {
    res.status(500).send({ error: "Failed to delete game data" })
  }
})

app.listen(3000, () => {
    console.log("Server is running on http://localhost:3000")
})
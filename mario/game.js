const config = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 300 },
            debug: false
        }
    },
    scene: {
        preload: preload,
        create: create,
        update: update
    }
};

const game = new Phaser.Game(config);

let player;
let platforms;
let coins;
let enemies;
let score = 0;
let lives = 3;
let scoreText;
let livesText;
let gameOver = false;

function preload() {
    this.load.image('sky', 'assets/sky.png');
    this.load.image('ground', 'assets/platform.png');
    
    // kwadraty zamiast sprite sheeetów :/
    const graphics = this.add.graphics();
    
    // mario niebieski
    graphics.fillStyle(0x0000ff);
    graphics.fillRect(0, 0, 32, 48);
    graphics.generateTexture('player', 32, 48);
    
    // monetka
    graphics.clear();
    graphics.fillStyle(0xffff00);
    graphics.fillCircle(8, 8, 8);
    graphics.generateTexture('coin', 16, 16);
    
    // muchomorki czerwone
    graphics.clear();
    graphics.fillStyle(0xff0000);
    graphics.fillRect(0, 0, 32, 32);
    graphics.generateTexture('enemy', 32, 32);
    
    graphics.destroy();
}

function create() {
    // granice gry
    this.physics.world.setBounds(0, 0, 3200, 600);
    
    this.add.image(400, 300, 'sky').setScrollFactor(0);
    
    // Kamera idzie za mario
    this.cameras.main.setBounds(0, 0, 3200, 600);
    
    // Tworzymy mario
    player = this.physics.add.sprite(100, 450, 'player');
    player.setBounce(0.2);
    player.setCollideWorldBounds(true);
    
    this.cameras.main.startFollow(player, true, 0.5, 0.5);
    
    scoreText = this.add.text(16, 16, 'Punkty: 0', { fontSize: '32px', fill: '#fff' })
        .setScrollFactor(0);
    livesText = this.add.text(16, 50, 'Życia: 3', { fontSize: '32px', fill: '#fff' })
        .setScrollFactor(0);
        
    // Platformy
    platforms = this.physics.add.staticGroup();
    platforms.create(400, 568, 'ground').setScale(2).refreshBody();
    platforms.create(600, 400, 'ground');
    platforms.create(50, 250, 'ground');
    platforms.create(750, 220, 'ground');

    // Monetki
    coins = this.physics.add.group({
        key: 'coin',
        repeat: 11,
        setXY: { x: 12, y: 0, stepX: 70 }
    });

    // Przeciwnicy
    enemies = this.physics.add.group();
    createEnemy(this, 300, 450);
    createEnemy(this, 500, 300);

    // Kolizje
    this.physics.add.collider(player, platforms);
    this.physics.add.collider(coins, platforms);
    this.physics.add.collider(enemies, platforms);
    this.physics.add.overlap(player, coins, collectCoin, null, this);
    this.physics.add.collider(player, enemies, hitEnemy, null, this);
}

function update() {
    if (gameOver) {
        return; 
    } 

    // czy win
    if (enemies.countActive() === 0 && coins.countActive() === 0) {
        gameOver = true;
        this.add.text(400, 300, 'WYGRANA!', { fontSize: '64px', fill: '#00ff00' })
            .setScrollFactor(0)
            .setOrigin(0.5);
        return;
    }

    // 
    enemies.children.iterate(function (enemy) {
        if (enemy && enemy.active) {
            if (enemy.x >= enemy.startX + 200) {
                enemy.direction = -1;
            } else if (enemy.x <= enemy.startX - 200) {
                enemy.direction = 1;
            }
            enemy.setVelocityX(100 * enemy.direction);
        }
    });

    const cursors = this.input.keyboard.createCursorKeys();

    if (cursors.left.isDown) {
        player.setVelocityX(-160);
        player.setFlipX(true);
    } else if (cursors.right.isDown) {
        player.setVelocityX(160);
        player.setFlipX(false);
    } else {
        player.setVelocityX(0);
    }

    if (cursors.up.isDown && player.body.touching.down) {
        player.setVelocityY(-330);
    }

    // czy mario sp
    if (player.y > 550) {
        lives--;
        livesText.setText('Życia: ' + lives);
        
        if (lives <= 0) {
            gameOver = true;
            this.add.text(400, 300, 'GAME OVER', { fontSize: '64px', fill: '#fff' })
                .setScrollFactor(0)
                .setOrigin(0.5);
        } else {
            player.setPosition(100, 450);
            player.setVelocityY(0);
            player.setVelocityX(0);
        }
    }
}

function createEnemy(scene, x, y) {
    const enemy = enemies.create(x, y, 'enemy');
    enemy.setBounce(0.2);
    enemy.setCollideWorldBounds(true);
    enemy.setVelocityX(100);
    
    enemy.startX = x;
    enemy.direction = 1;
}

function collectCoin(player, coin) {
    coin.disableBody(true, true);
    score += 10;
    scoreText.setText('Punkty: ' + score);
}

function hitEnemy(player, enemy) {
    if (player.body.touching.down && enemy.body.touching.up) {
        enemy.destroy();
        score += 20;
        scoreText.setText('Punkty: ' + score);
        player.setVelocityY(-200);
    } else {
        lives--;
        livesText.setText('Życia: ' + lives);
        
        if (lives <= 0) {
            gameOver = true;
            this.add.text(400, 300, 'GAME OVER', { fontSize: '64px', fill: '#fff' })
                .setScrollFactor(0)
                .setOrigin(0.5);
        } else {
            player.setPosition(100, 450);
            player.setVelocityY(0);
            player.setVelocityX(0);
        }
    }
} 
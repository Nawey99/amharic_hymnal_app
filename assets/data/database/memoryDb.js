import Song from '../models/Song.js';

class MemoryDatabase {
  constructor() {
    this.songs = new Map();
    this.seedData();
  }

  seedData() {
    const sampleSongs = [
      {
        title: "Bohemian Rhapsody",
        artist: "Queen",
        album: "A Night at the Opera",
        genre: "Rock",
        year: 1975,
        duration: 355,
        rating: 5
      },
      {
        title: "Stairway to Heaven",
        artist: "Led Zeppelin",
        album: "Led Zeppelin IV",
        genre: "Rock",
        year: 1971,
        duration: 482,
        rating: 5
      },
      {
        title: "Hotel California",
        artist: "Eagles",
        album: "Hotel California",
        genre: "Rock",
        year: 1976,
        duration: 391,
        rating: 4
      },
      {
        title: "Imagine",
        artist: "John Lennon",
        album: "Imagine",
        genre: "Pop",
        year: 1971,
        duration: 183,
        rating: 5
      },
      {
        title: "Billie Jean",
        artist: "Michael Jackson",
        album: "Thriller",
        genre: "Pop",
        year: 1982,
        duration: 294,
        rating: 4
      }
    ];

    sampleSongs.forEach(songData => {
      const song = new Song(songData);
      this.songs.set(song.id, song);
    });
  }

  getAllSongs() {
    return Array.from(this.songs.values());
  }

  getSongById(id) {
    return this.songs.get(id);
  }

  createSong(data) {
    const song = new Song(data);
    this.songs.set(song.id, song);
    return song;
  }

  updateSong(id, data) {
    const song = this.songs.get(id);
    if (!song) {
      return null;
    }
    song.update(data);
    return song;
  }

  deleteSong(id) {
    const song = this.songs.get(id);
    if (!song) {
      return null;
    }
    this.songs.delete(id);
    return song;
  }

  searchSongs(query) {
    const lowercaseQuery = query.toLowerCase();
    return this.getAllSongs().filter(song =>
      song.title.toLowerCase().includes(lowercaseQuery) ||
      song.artist.toLowerCase().includes(lowercaseQuery) ||
      song.album.toLowerCase().includes(lowercaseQuery) ||
      song.genre.toLowerCase().includes(lowercaseQuery)
    );
  }

  filterSongs(filters) {
    let songs = this.getAllSongs();

    if (filters.genre) {
      songs = songs.filter(song => 
        song.genre.toLowerCase().includes(filters.genre.toLowerCase())
      );
    }

    if (filters.year) {
      songs = songs.filter(song => song.year === parseInt(filters.year));
    }

    if (filters.artist) {
      songs = songs.filter(song =>
        song.artist.toLowerCase().includes(filters.artist.toLowerCase())
      );
    }

    return songs;
  }
}

export default new MemoryDatabase();